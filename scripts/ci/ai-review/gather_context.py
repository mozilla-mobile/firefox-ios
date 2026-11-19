#!/usr/bin/env python3
"""Collect what the AI review reads about a pull request into a directory.

Runs before Claude, with a read-only token, so Claude needs no GitHub access.
The diff is taken at --commit, the head commit from the workflow's event, so it
matches the code checked out for Claude even if someone pushes during the run.

    pr.md         title, author, branches, description
    diff.patch    the changes, file by file
    files.json    the changed files and their patches (used again to post the review)
    comments.md   the conversation, reviews and inline review comments so far,
                  with earlier AI reviews and their findings marked as such
    since-last-review.md
                  what changed since the last AI review, so a follow-up
                  review can cover only that
    tickets.md    the linked GitHub issues (Jira tickets are ignored for now)

Usage: gather_context.py --repo OWNER/NAME --pr NUMBER --commit SHA --out DIR
"""

import argparse
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import quote

from common import ai_findings, gh_api, is_ai_review, review_threads

MAX_ISSUES = 5
# GitHub's compare API lists at most this many files.
MAX_COMPARE_FILES = 300
MAX_ISSUE_COMMENTS = 20

_KEYWORD_RE = re.compile(
    r"\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#(\d+)\b", re.IGNORECASE
)


def changed_files(repo: str, base_ref: str, commit: str) -> list[dict]:
    """The pull request's files at a fixed head commit.

    The pull request files API always shows the latest push, so compare instead.
    A three-dot compare diffs from the merge base, as the pull request does, and
    the merge base of a fixed head with the base branch stays put.
    """
    compare = gh_api(f"repos/{repo}/compare/{quote(base_ref, safe='')}...{commit}?per_page=1")
    return compare["files"]


def linked_issues(repo: str, text: str) -> list[int]:
    url_re = re.compile(rf"github\.com/{re.escape(repo)}/issues/(\d+)", re.IGNORECASE)
    numbers = [int(n) for n in url_re.findall(text) + _KEYWORD_RE.findall(text)]
    return list(dict.fromkeys(numbers))[:MAX_ISSUES]


def write_pr(out: Path, pr: dict, commit: str, files: list[dict]) -> None:
    labels = ", ".join(label["name"] for label in pr["labels"]) or "none"
    additions = sum(f["additions"] for f in files)
    deletions = sum(f["deletions"] for f in files)
    count = f"{len(files)}+" if len(files) >= MAX_COMPARE_FILES else str(len(files))
    out.joinpath("pr.md").write_text(
        f"# {pr['title']}\n\n"
        f"- Author: {pr['user']['login']}\n"
        f"- Branch: {pr['head']['label']} -> {pr['base']['ref']}\n"
        f"- Head commit: {commit}\n"
        f"- Labels: {labels}\n"
        f"- Changes: {count} files, +{additions} -{deletions}\n\n"
        f"## Description\n\n{pr['body'] or '(empty)'}\n"
    )


def write_diff(out: Path, files: list[dict]) -> None:
    parts = []
    for f in files:
        header = f"diff --git a/{f.get('previous_filename', f['filename'])} b/{f['filename']}"
        if "patch" in f:
            parts.append(f"{header}\n({f['status']})\n{f['patch']}\n")
        else:
            parts.append(f"{header}\n({f['status']}, no diff: binary or too large)\n")
    if len(files) >= MAX_COMPARE_FILES:
        parts.append(f"(Only the first {MAX_COMPARE_FILES} files are shown.)\n")
    out.joinpath("diff.patch").write_text("\n".join(parts))
    out.joinpath("files.json").write_text(json.dumps(files, indent=1))


def write_comments(out: Path, conversation, reviews, inline, threads) -> None:
    ai_reviews = {r["id"]: r["commit_id"] for r in reviews if is_ai_review(r)}
    findings = ai_findings(reviews, inline, threads)
    lines = ["# Discussion so far", ""]
    for c in conversation:
        lines += [f"## Comment by {c['user']['login']}", "", c["body"] or "", ""]
    for r in reviews:
        if r["id"] in ai_reviews:
            lines += [f"## Earlier AI review of commit {r['commit_id'][:12]}", "", r["body"], ""]
        elif r["body"]:
            lines += [f"## Review by {r['user']['login']} ({r['state']})", "", r["body"], ""]
    for c in inline:
        where = f"{c['path']}:{c.get('line') or c.get('original_line')}"
        if finding := findings.get(c["id"]):
            state = "resolved" if (finding["thread"] or {}).get("resolved") else "unresolved"
            heading = (
                f"## Earlier AI finding {c['id']} on {where} "
                f"(review of commit {finding['commit'][:12]}, {state})"
            )
        elif c.get("in_reply_to_id"):
            heading = f"## Reply by {c['user']['login']} to comment {c['in_reply_to_id']}"
        else:
            heading = f"## Inline comment by {c['user']['login']} on {where}"
        lines += [heading, "", c["body"], ""]
    if len(lines) == 2:
        lines.append("(none)")
    out.joinpath("comments.md").write_text("\n".join(lines))


def write_since_last_review(out: Path, repo: str, reviews: list[dict], commit: str) -> None:
    earlier = [r for r in reviews if is_ai_review(r)]
    path = out.joinpath("since-last-review.md")
    if not earlier:
        path.write_text("# Since the last AI review\n\nThere is no earlier AI review.\n")
        return
    last = earlier[-1]["commit_id"]
    lines = ["# Since the last AI review", "", f"The last AI review was of commit {last}.", ""]
    if last == commit:
        lines.append("That is the commit being reviewed now: nothing has changed since.")
    else:
        try:
            files = gh_api(f"repos/{repo}/compare/{last}...{commit}?per_page=1")["files"]
        except subprocess.CalledProcessError:
            lines.append(
                "It can't be compared with the commit being reviewed now, probably "
                "because the branch was force-pushed. Treat every change as new."
            )
        else:
            lines += [
                f"Changes from it to the commit being reviewed now ({commit}). If the "
                "branch was rebased, these include changes from the base branch.",
                "",
            ]
            for f in files:
                lines += [f"diff --git a/{f['filename']} b/{f['filename']}", f"({f['status']})"]
                lines += [f.get("patch", "(no diff: binary or too large)"), ""]
            if not files:
                lines.append("(no file changes)")
    path.write_text("\n".join(lines) + "\n")


def write_tickets(out: Path, repo: str, pr: dict) -> None:
    text = f"{pr['title']}\n{pr['body'] or ''}"
    lines = ["# Linked tickets", ""]
    for number in linked_issues(repo, text):
        try:
            issue = gh_api(f"repos/{repo}/issues/{number}")
        except subprocess.CalledProcessError:
            lines += [f"## GitHub issue #{number}", "", "(could not be read)", ""]
            continue
        labels = ", ".join(label["name"] for label in issue["labels"]) or "none"
        lines += [
            f"## GitHub issue #{number}: {issue['title']}",
            "",
            f"- State: {issue['state']}",
            f"- Labels: {labels}",
            "",
            issue["body"] or "(empty)",
            "",
        ]
        if issue["comments"]:
            comments = gh_api(f"repos/{repo}/issues/{number}/comments?per_page={MAX_ISSUE_COMMENTS}")
            for c in comments:
                lines += [f"### Comment by {c['user']['login']}", "", c["body"] or "", ""]
    if len(lines) == 2:
        lines.append("(no GitHub issues linked in the title or description)")
    out.joinpath("tickets.md").write_text("\n".join(lines))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--pr", required=True, type=int)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    repo, number, commit, out = args.repo, args.pr, args.commit, args.out
    out.mkdir(parents=True, exist_ok=True)

    pr = gh_api(f"repos/{repo}/pulls/{number}")
    files = changed_files(repo, pr["base"]["ref"], commit)
    write_pr(out, pr, commit, files)
    write_diff(out, files)
    reviews = gh_api(f"repos/{repo}/pulls/{number}/reviews?per_page=100", paginate=True)
    write_comments(
        out,
        gh_api(f"repos/{repo}/issues/{number}/comments?per_page=100", paginate=True),
        reviews,
        gh_api(f"repos/{repo}/pulls/{number}/comments?per_page=100", paginate=True),
        review_threads(repo, number),
    )
    write_since_last_review(out, repo, reviews, commit)
    write_tickets(out, repo, pr)


if __name__ == "__main__":
    main()

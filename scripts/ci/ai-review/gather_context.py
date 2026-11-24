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
                  how the pull request's diff changed since the last AI review,
                  without the base branch's changes, so a follow-up review can
                  cover only the author's
    tickets.md    the linked GitHub issues (Jira tickets are ignored for now)

Usage: gather_context.py --repo OWNER/NAME --pr NUMBER --commit SHA --out DIR
"""

import argparse
import difflib
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


_HUNK_RE = re.compile(r"^@@ [^@]* @@", re.MULTILINE)


def _patch_lines(f: dict) -> list[str]:
    """A file's patch without hunk line numbers, which shift when the base moves."""
    if "patch" not in f:
        return ["(no diff: binary or too large)"]
    return _HUNK_RE.sub("@@", f["patch"]).splitlines()


def write_since_last_review(
    out: Path, repo: str, reviews: list[dict], base_ref: str, files: list[dict], commit: str
) -> None:
    """What the author changed since the last AI review, without the base branch's changes.

    Diffing the last reviewed commit against this one would also pick up
    everything the base branch gained if the branch was rebased or merged with
    it, and after a rebase the whole pull request again. So compare the pull
    request's diff then with its diff now: the base branch's changes are in
    neither, and only what the author changed differs.
    """
    earlier = [r for r in reviews if is_ai_review(r)]
    path = out.joinpath("since-last-review.md")
    if not earlier:
        path.write_text("# Since the last AI review\n\nThere is no earlier AI review.\n")
        return
    last = earlier[-1]["commit_id"]
    lines = ["# Since the last AI review", "", f"The last AI review was of commit {last}.", ""]
    if last == commit:
        lines.append("That is the commit being reviewed now: nothing has changed since.")
        path.write_text("\n".join(lines) + "\n")
        return
    try:
        before = changed_files(repo, base_ref, last)
    except subprocess.CalledProcessError:
        lines.append(
            "Its diff can no longer be read, so treat every change in the pull "
            "request as new."
        )
        path.write_text("\n".join(lines) + "\n")
        return

    lines += [
        f"How the pull request's diff changed from that commit to {commit}. Changes "
        "the base branch gained, from a rebase or merge, are already left out.",
        "",
        "For a file whose diff changed, this is a diff of its diff: the first "
        "character says whether a line was dropped (-) or added (+) since the last "
        "review, and the rest is the line as it appears in the pull request's diff.",
        "",
    ]
    old = {f["filename"]: f for f in before}
    new = {f["filename"]: f for f in files}
    changed = False
    for name, f in new.items():
        if name not in old:
            changed = True
            lines += [f"## {name}: newly changed by the pull request ({f['status']})", ""]
            lines += _patch_lines(f) + [""]
        elif _patch_lines(old[name]) != _patch_lines(f):
            changed = True
            lines += [f"## {name}: its changes are different", ""]
            lines += list(
                difflib.unified_diff(
                    _patch_lines(old[name]), _patch_lines(f), lineterm="", n=2
                )
            )[2:]
            lines.append("")
    for name in old.keys() - new.keys():
        changed = True
        lines += [f"## {name}: no longer changed by the pull request", ""]
    if not changed:
        lines.append("(the pull request's changes are the same)")
    if max(len(before), len(files)) >= MAX_COMPARE_FILES:
        lines.append(f"(Only the first {MAX_COMPARE_FILES} files of each diff are compared.)")
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
    base_ref = pr["base"]["ref"]
    files = changed_files(repo, base_ref, commit)
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
    write_since_last_review(out, repo, reviews, base_ref, files, commit)
    write_tickets(out, repo, pr)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Post Claude's review findings to the pull request as one GitHub review.

A finding becomes an inline comment when its lines are in the diff; GitHub
rejects the whole review otherwise, so the rest are listed in the review body.

Follow-ups reply to earlier AI findings that later commits tried to address,
saying whether they're fixed, and resolve the thread of each one that is. The
review body lists them with links, so the summary needn't describe those
changes. Only unresolved threads started by an earlier AI review are touched,
whatever the follow-up asks for.

If the pull request's head has moved past the reviewed commit, nothing is
posted and a comment says so: the findings may no longer apply.

Usage: post_review.py --repo OWNER/NAME --pr NUMBER --commit SHA
                      --review review.json --files files.json
                      [--run-url URL] [--dry-run]
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

from common import HEADER, ai_findings, gh_api, review_threads

_HUNK_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@")
_TITLE_RE = re.compile(r"^\*\*\[P\d\] (.+?)\*\*")
_SEVERITY_ORDER = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}
_FOLLOWUP_LABELS = {
    "fixed": "✅ **Fixed**",
    "partly_fixed": "🟡 **Partly fixed**",
    "not_fixed": "❌ **Not fixed**",
}
_RESOLVE_MUTATION = """
mutation($thread: ID!) { resolveReviewThread(input: {threadId: $thread}) { thread { id } } }
"""


def commentable_lines(files: list[dict]) -> dict[str, dict[int, int]]:
    """For each file, the new-side lines in its diff, mapped to their hunk.

    Added and unchanged context lines can carry a comment; a multi-line comment
    has to stay within one hunk.
    """
    lines: dict[str, dict[int, int]] = {}
    for f in files:
        in_file = lines.setdefault(f["filename"], {})
        hunk, line = -1, 0
        for row in f.get("patch", "").splitlines():
            if match := _HUNK_RE.match(row):
                hunk += 1
                line = int(match.group(1))
            elif hunk < 0 or row.startswith("-") or row.startswith("\\"):
                continue
            else:
                in_file[line] = hunk
                line += 1
    return lines


def placeable(finding: dict, lines: dict[str, dict[int, int]]) -> bool:
    in_file = lines.get(finding["path"], {})
    end = finding["line"]
    start = finding.get("start_line", end)
    return (
        end in in_file
        and start in in_file
        and start <= end
        and in_file[start] == in_file[end]
    )


def repro_text(repro: dict) -> str:
    """Steps to reproduce, expected and actual results, folded away."""
    parts = []
    if steps := repro.get("steps"):
        parts += ["**Steps to reproduce**", ""]
        parts += [f"{i}. {step}" for i, step in enumerate(steps, 1)]
        parts.append("")
    for key, label in (("expected", "Expected"), ("actual", "Actual")):
        if repro.get(key):
            parts += [f"**{label}:** {repro[key]}", ""]
    if not parts:
        return ""
    return "\n".join(["<details>", "<summary>Reproduce</summary>", "", *parts, "</details>"])


def finding_text(finding: dict) -> str:
    """Everything after a finding's title."""
    parts = [finding["description"], "", f"**Fix:** {finding['fix']}"]
    if repro := repro_text(finding.get("repro") or {}):
        parts += ["", repro]
    return "\n".join(parts)


def comment_text(finding: dict) -> str:
    return f"**[{finding['severity']}] {finding['title']}**\n\n{finding_text(finding)}"


def inline_comment(finding: dict) -> dict:
    comment = {
        "path": finding["path"],
        "line": finding["line"],
        "side": "RIGHT",
        "body": comment_text(finding),
    }
    start = finding.get("start_line")
    if start is not None and start != finding["line"]:
        comment |= {"start_line": start, "start_side": "RIGHT"}
    return comment


def commit_link(repo: str, pr: int, sha: str) -> str:
    """A short commit SHA linking to the commit in the pull request."""
    return f"[`{sha[:12]}`](https://github.com/{repo}/pull/{pr}/commits/{sha})"


def followup_line(followup: dict, finding: dict) -> str:
    """A link to the earlier finding a follow-up replies to."""
    match = _TITLE_RE.match(finding["body"])
    title = match.group(1) if match else "Earlier finding"
    return f"- {_FOLLOWUP_LABELS[followup['status']]}: [{title}]({finding['url']})"


def review_body(
    summary: str, unplaced: list[dict], followups: list[tuple[dict, dict]], commit: str,
    run_url: str | None,
) -> str:
    parts = [HEADER, "", summary.strip()]
    if followups:
        parts += ["", "#### Earlier findings", ""]
        parts += [followup_line(followup, finding) for followup, finding in followups]
    if unplaced:
        parts += ["", "#### Other findings", ""]
        for f in unplaced:
            where = f"`{f['path']}:{f['line']}`"
            parts += [f"**[{f['severity']}] {f['title']}** ({where})", "", finding_text(f), ""]
    footer = f"Reviewed commit {commit}. Findings can be wrong; treat them as suggestions."
    if run_url:
        footer += f" [Workflow run]({run_url})"
    parts += ["", "---", f"<sub>{footer}</sub>"]
    return "\n".join(parts)


def build_review(
    review: dict, files: list[dict], followups: list[tuple[dict, dict]], repo: str, pr: int,
    commit: str, run_url: str | None,
) -> dict:
    lines = commentable_lines(files)
    findings = sorted(review["findings"], key=lambda f: _SEVERITY_ORDER[f["severity"]])
    inline = [f for f in findings if placeable(f, lines)]
    unplaced = [f for f in findings if not placeable(f, lines)]
    return {
        "commit_id": commit,
        "event": "COMMENT",
        "body": review_body(
            review["summary"], unplaced, followups, commit_link(repo, pr, commit), run_url
        ),
        "comments": [inline_comment(f) for f in inline],
    }


def current_head(repo: str, pr: int) -> str:
    return subprocess.run(
        ["gh", "api", f"repos/{repo}/pulls/{pr}", "--jq", ".head.sha"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def stale_notice(repo: str, pr: int, reviewed: str, head: str, run_url: str | None) -> str:
    text = (
        f"Skipped the AI code review: it reviewed {commit_link(repo, pr, reviewed)}, but the "
        f"pull request is now at {commit_link(repo, pr, head)}. Add the `ai-review` label again to review "
        "the latest commit."
    )
    if run_url:
        text += f" [Workflow run]({run_url})"
    return text


def post(repo: str, pr: int, payload: dict) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["gh", "api", "--method", "POST", f"repos/{repo}/pulls/{pr}/reviews", "--input", "-"],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
    )


def followup_text(followup: dict, commit_ref: str) -> str:
    return f"{_FOLLOWUP_LABELS[followup['status']]} as of {commit_ref}\n\n{followup['note']}"


def open_followups(repo: str, pr: int, followups: list[dict]) -> list[tuple[dict, dict]]:
    """The follow-ups on unresolved earlier AI findings, each with its finding."""
    if not followups:
        return []
    reviews = gh_api(f"repos/{repo}/pulls/{pr}/reviews?per_page=100", paginate=True)
    inline = gh_api(f"repos/{repo}/pulls/{pr}/comments?per_page=100", paginate=True)
    findings = ai_findings(reviews, inline, review_threads(repo, pr))
    valid = []
    for followup in followups:
        finding = findings.get(followup["comment_id"])
        if finding is None or finding["thread"] is None or finding["thread"]["resolved"]:
            print(f"::warning::Skipping follow-up on {followup['comment_id']}: not an open AI finding")
            continue
        valid.append((followup, finding))
    return valid


def post_followups(repo: str, pr: int, followups: list[tuple[dict, dict]], commit: str) -> None:
    """Reply to earlier AI findings, and resolve the threads of fixed ones.

    A failure here is reported but doesn't fail the run: the review is posted.
    """
    for followup, finding in followups:
        comment_id, thread = followup["comment_id"], finding["thread"]
        reply = subprocess.run(
            [
                "gh", "api", "--method", "POST",
                f"repos/{repo}/pulls/{pr}/comments/{comment_id}/replies",
                "-f", f"body={followup_text(followup, commit_link(repo, pr, commit))}",
            ],
            capture_output=True,
            text=True,
        )
        if reply.returncode != 0:
            print(f"::warning::Couldn't reply to {comment_id}: {reply.stderr}")
            continue
        if followup["status"] != "fixed":
            continue
        resolve = subprocess.run(
            [
                "gh", "api", "graphql", "-f", f"query={_RESOLVE_MUTATION}",
                "-f", f"thread={thread['id']}",
            ],
            capture_output=True,
            text=True,
        )
        if resolve.returncode != 0:
            print(f"::warning::Couldn't resolve the thread of {comment_id}: {resolve.stderr}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--pr", required=True, type=int)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--review", required=True, type=Path)
    parser.add_argument("--files", required=True, type=Path)
    parser.add_argument("--run-url")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    review = json.loads(args.review.read_text())
    files = json.loads(args.files.read_text())
    followups = open_followups(args.repo, args.pr, review.get("followups", []))
    payload = build_review(review, files, followups, args.repo, args.pr, args.commit, args.run_url)

    if args.dry_run:
        print(json.dumps(payload, indent=2))
        for followup, _ in followups:
            ref = commit_link(args.repo, args.pr, args.commit)
            print(f"Reply to {followup['comment_id']}:\n{followup_text(followup, ref)}")
        return

    head = current_head(args.repo, args.pr)
    if head != args.commit:
        print(f"The head moved to {head}; skipping the review of {args.commit}.")
        subprocess.run(
            [
                "gh", "api", "--method", "POST", f"repos/{args.repo}/issues/{args.pr}/comments",
                "-f", f"body={stale_notice(args.repo, args.pr, args.commit, head, args.run_url)}",
            ],
            check=True,
        )
        return

    result = post(args.repo, args.pr, payload)
    if result.returncode != 0 and payload["comments"]:
        # GitHub rejects the whole review over one bad comment position. Fall
        # back to listing every finding in the body.
        print(f"Inline review failed, posting without inline comments:\n{result.stderr}")
        payload = build_review(review, [], followups, args.repo, args.pr, args.commit, args.run_url)
        result = post(args.repo, args.pr, payload)
    if result.returncode != 0:
        sys.exit(f"Could not post the review:\n{result.stderr}")
    print(json.loads(result.stdout)["html_url"])
    post_followups(args.repo, args.pr, followups, args.commit)


if __name__ == "__main__":
    main()

"""GitHub helpers shared by the AI review scripts."""

import json
import subprocess

HEADER = "### 🤖 AI code review (experimental)"
# Reviews are posted with the workflow's token.
BOT_LOGIN = "github-actions[bot]"

_THREADS_QUERY = """
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes { id isResolved comments(first: 1) { nodes { databaseId } } }
      }
    }
  }
}
"""


def gh_api(path: str, *, paginate: bool = False):
    args = ["gh", "api", path]
    if paginate:
        args += ["--paginate", "--slurp"]
    out = subprocess.run(args, check=True, capture_output=True, text=True).stdout
    data = json.loads(out)
    if paginate:
        return [item for page in data for item in page]
    return data


def gh_api_raw(path: str) -> str:
    """A file's contents from the contents API, as text."""
    args = ["gh", "api", "-H", "Accept: application/vnd.github.raw", path]
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def is_ai_review(review: dict) -> bool:
    return review["user"]["login"] == BOT_LOGIN and (review["body"] or "").startswith(HEADER)


def review_threads(repo: str, pr: int) -> dict[int, dict]:
    """Each review thread, keyed by the id of the comment that starts it."""
    owner, name = repo.split("/")
    out = subprocess.run(
        [
            "gh", "api", "graphql", "-f", f"query={_THREADS_QUERY}",
            "-f", f"owner={owner}", "-f", f"name={name}", "-F", f"number={pr}",
        ],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    nodes = json.loads(out)["data"]["repository"]["pullRequest"]["reviewThreads"]["nodes"]
    return {
        node["comments"]["nodes"][0]["databaseId"]: {"id": node["id"], "resolved": node["isResolved"]}
        for node in nodes
        if node["comments"]["nodes"]
    }


def ai_findings(reviews: list[dict], inline: list[dict], threads: dict[int, dict]) -> dict[int, dict]:
    """The inline comments earlier AI reviews posted, keyed by comment id.

    Each has the reviewed commit, its body and link, and its thread. Only these
    can be followed up.
    """
    ai_reviews = {r["id"]: r["commit_id"] for r in reviews if is_ai_review(r)}
    return {
        c["id"]: {
            "commit": ai_reviews[c["pull_request_review_id"]],
            "body": c["body"],
            "url": c["html_url"],
            "thread": threads.get(c["id"]),
        }
        for c in inline
        if c.get("pull_request_review_id") in ai_reviews and not c.get("in_reply_to_id")
    }

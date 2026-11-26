#!/usr/bin/env python3
"""Print the link to the latest AI review if it already covers --commit.

Lets the workflow skip running the model again on a commit that hasn't
changed. Prints nothing if there's no AI review of that commit yet.

Usage: check_reviewed.py --repo OWNER/NAME --pr NUMBER --commit SHA
"""

import argparse

from common import gh_api, is_ai_review


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--pr", required=True, type=int)
    parser.add_argument("--commit", required=True)
    args = parser.parse_args()

    reviews = gh_api(f"repos/{args.repo}/pulls/{args.pr}/reviews?per_page=100", paginate=True)
    earlier = [r for r in reviews if is_ai_review(r)]
    if earlier and earlier[-1]["commit_id"] == args.commit:
        print(earlier[-1]["html_url"])


if __name__ == "__main__":
    main()

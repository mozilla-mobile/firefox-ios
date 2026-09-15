import argparse
import json
import os
import urllib.request
from collections import defaultdict

TOKEN = os.environ["BITRISE_ACCESS_TOKEN"]
APP_SLUG = os.environ["BITRISE_APP_SLUG"]
URL = f"https://api.bitrise.io/v0.1/apps/{APP_SLUG}/build-requests"


HEADERS = {
    "Authorization": TOKEN,
    "Content-Type": "application/json",
}

# Calls the Bitrise API and returns JSON.
def api(url, method="GET", data=None):
    body = json.dumps(data).encode() if data else None
    request = urllib.request.Request(
        url,
        method=method,
        headers=HEADERS,
        data=body,
    )

    with urllib.request.urlopen(request) as response:
        return json.load(response)


# Groups manual approval requests by pull request ID.
def group_builds_by_pr(builds):
    builds_by_pr = defaultdict(list)

    for build in builds:
        pr = build["build_params"].get("pull_request_id")
        if pr:
            builds_by_pr[pr].append(build)

    return builds_by_pr


# Keeps the newest request for each PR and declines any older duplicates.
def decline_duplicate_builds(builds_by_pr, dry_run=False):
    duplicates = {
        pr: sorted(builds, key=lambda b: b["created_at"], reverse=True)
        for pr, builds in builds_by_pr.items()
        if len(builds) >= 2
    }

    for pr, builds in duplicates.items():
        keep, *stale = builds
        title = (keep["build_params"].get("commit_message") or "\n").splitlines()[0][:100]
        print(f"PR #{pr} ({title})")
        print(f"  * Found {len(stale)} duplicate{'s' if len(stale) != 1 else ''}")
        print(f"  keeping {keep['slug']}")

        for duplicate in stale:
            slug = duplicate["slug"]
            if dry_run:
                print(f"    [dry run] would decline {slug}")
            else:
                print(f"    declining {slug}")
                api(f"{URL}/{slug}", method="PATCH", data={"is_approved": False})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    builds = api(URL)["data"]
    builds_by_pr = group_builds_by_pr(builds)
    decline_duplicate_builds(builds_by_pr, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
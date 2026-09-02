#!/usr/bin/env bash
#
# Merges the latest main into the Xcode 27 / iOS 27 canary branch and pushes it,
# which triggers pipeline_build_and_test on the osx-xcode-27.0.x-edge stack.
#
# Run daily (cron, launchd, or a Bitrise scheduled build). Merge is used rather than
# rebase so the branch history stays stable for reviewers and no force-push is needed.
#
# Exits non-zero on merge conflict without pushing, so a failed sync is visible
# rather than silently skipped.

set -euo pipefail

BRANCH="${CANARY_BRANCH:-cs/mte-6112-xcode27-firefox-only}"
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

cd "$REPO_DIR"

echo "==> repo: $REPO_DIR"
echo "==> branch: $BRANCH"

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "ERROR: working tree is dirty; refusing to sync." >&2
    exit 1
fi

git fetch --prune origin
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"

BEFORE=$(git rev-parse HEAD)
MAIN=$(git rev-parse origin/main)
echo "==> branch at ${BEFORE:0:10}, origin/main at ${MAIN:0:10}"

if git merge-base --is-ancestor "$MAIN" HEAD; then
    echo "==> already contains origin/main; nothing to merge."
    exit 0
fi

if ! git merge --no-edit origin/main; then
    echo "ERROR: merge conflict against origin/main. Resolve manually:" >&2
    git --no-pager diff --name-only --diff-filter=U >&2
    git merge --abort
    exit 2
fi

echo "==> merged; pushing to trigger CI"
git push origin "$BRANCH"
echo "==> done: ${BEFORE:0:10} -> $(git rev-parse --short HEAD)"

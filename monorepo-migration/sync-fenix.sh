#!/usr/bin/env bash

set -ex

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
CURRENT_REPO_PATH="$(dirname -- "$SCRIPT_DIR")"

REPO_NAME_TO_SYNC='fenix'
MAIN_BRANCH_NAME='main'

CURRENT_MAJOR_VERSION="$(git show "$MAIN_BRANCH_NAME":version.txt | cut -d'.' -f1)"
CURRENT_BETA_VERSION="$(( CURRENT_MAJOR_VERSION - 1 ))"
CURRENT_RELEASE_VERSION="$(( CURRENT_BETA_VERSION - 1 ))"
BRANCHES_TO_SYNC_ON_CURRENT_REPO=("$MAIN_BRANCH_NAME" "releases_v$CURRENT_BETA_VERSION" "releases_v$CURRENT_RELEASE_VERSION")
BRANCHES_TO_SYNC_ON_TMP_REPO=("$MAIN_BRANCH_NAME" "releases_v$CURRENT_BETA_VERSION.0.0" "releases_v$CURRENT_RELEASE_VERSION.0.0")
PREP_BRANCHES=("$REPO_NAME_TO_SYNC-prep" "$REPO_NAME_TO_SYNC-prep-$CURRENT_BETA_VERSION" "$REPO_NAME_TO_SYNC-prep-$CURRENT_RELEASE_VERSION")

TMP_REPO_PATH="/tmp/git/$REPO_NAME_TO_SYNC"
TMP_REPO_BRANCH_NAME='firefox-android'
MERGE_COMMIT_MESSAGE=$(cat <<EOF
Merge https://github.com/mozilla-mobile/$REPO_NAME_TO_SYNC repository

The history was slightly altered before merging it:
  * All files from $REPO_NAME_TO_SYNC are now under its own subdirectory
  * All commits messages were rewritten to link issues and pull requests to the former repository
  * All commits messages were prefixed with [$REPO_NAME_TO_SYNC]
EOF
)

EXPRESSIONS_FILE_PATH="$SCRIPT_DIR/data/message-expressions.txt"
UTC_NOW="$(date -u '+%Y%m%d%H%M%S')"
PREP_BRANCH_BACKUP_SUFFIX="backup-$UTC_NOW"


function _is_github_authenticated() {
    set +e
    ssh -T git@github.com
    exit_code=$?
    set -e
    if [[ $exit_code == 1 ]]; then
        # user is authenticated, but fails to open a shell with GitHub
        return 0
    fi
    exit "$exit_code"
}

function _test_prerequisites() {
    _is_github_authenticated
    git filter-repo --version > /dev/null || (echo 'ERROR: Please install git-filter-repo: https://github.com/newren/git-filter-repo/blob/main/INSTALL.md'; exit 1)
}

function _setup_temporary_repo() {
    rm -rf "$TMP_REPO_PATH"
    mkdir -p "$TMP_REPO_PATH"

    git clone "git@github.com:mozilla-mobile/$REPO_NAME_TO_SYNC.git" "$TMP_REPO_PATH"
    cd "$TMP_REPO_PATH"
    git fetch origin "$TMP_REPO_BRANCH_NAME"
}

function _update_repo_branch() {
    git checkout "$TMP_REPO_BRANCH_NAME"
    git rebase main
    git push origin "$TMP_REPO_BRANCH_NAME" --force
}

function _update_repo_numbers() {
    cd "$CURRENT_REPO_PATH"
    "$SCRIPT_DIR/generate-repo-numbers.py"
    "$SCRIPT_DIR/generate-replace-message-expressions.py"
    git switch "$MAIN_BRANCH_NAME"
    git add 'monorepo-migration/data'
    git commit -m "monorepo-migration: Fetch latest repo numbers and regexes"
    git switch -
}

function _rewrite_git_history() {
    cd "$TMP_REPO_PATH"
    git filter-repo \
        --to-subdirectory-filter "$REPO_NAME_TO_SYNC/" \
        --replace-message "$EXPRESSIONS_FILE_PATH" \
        --force
}

function _back_up_prep_branch() {
    local prep_branch="$1"

    cd "$CURRENT_REPO_PATH"
    if git rev-parse --quiet --verify "$prep_branch" > /dev/null; then
        git branch --move "$prep_branch" "$prep_branch-$PREP_BRANCH_BACKUP_SUFFIX"
    fi
}

function _reset_prep_branch() {
    local branch_on_current_repo="$1"
    local prep_branch="$2"

    _back_up_prep_branch "$prep_branch"
    cd "$CURRENT_REPO_PATH"
    git checkout "$branch_on_current_repo"
    git pull
    git checkout -b "$prep_branch"
}

function _merge_histories() {
    cd "$TMP_REPO_PATH"
    git checkout "$branch_on_tmp_repo"

    cd "$CURRENT_REPO_PATH"
    git pull --no-edit --allow-unrelated-histories --no-rebase --force "$TMP_REPO_PATH"
    git commit --amend --message "$MERGE_COMMIT_MESSAGE"
}

function _update_prep_branches() {
    for i in "${!BRANCHES_TO_SYNC_ON_CURRENT_REPO[@]}"; do
        branch_on_current_repo="${BRANCHES_TO_SYNC_ON_CURRENT_REPO[i]}"
        branch_on_tmp_repo="${BRANCHES_TO_SYNC_ON_TMP_REPO[i]}"
        prep_branch="${PREP_BRANCHES[i]}"

        echo "Processing $branch_on_current_repo + $branch_on_tmp_repo => $prep_branch"

        _reset_prep_branch "$branch_on_current_repo" "$prep_branch"
        _merge_histories "$branch_on_tmp_repo"
    done
}


_test_prerequisites
_setup_temporary_repo
_update_repo_branch
_update_repo_numbers
_rewrite_git_history
_update_prep_branches

git checkout "${PREP_BRANCHES[0]}"

cat <<EOF
$REPO_NAME_TO_SYNC has been sync'd and merged to the following branches:
    ${PREP_BRANCHES[@]}

You are currently on ${PREP_BRANCHES[0]}.
You can now inspect the changes and push them once ready.

If something went wrong, you still have a copy of the former branches.
They're suffixed by '$PREP_BRANCH_BACKUP_SUFFIX'

EOF

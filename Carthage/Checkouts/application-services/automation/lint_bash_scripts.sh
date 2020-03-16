#!/usr/bin/env bash

if [[ ! -f "$PWD/automation/lint_bash_scripts.sh" ]]
then
    echo "lint_bash_scripts.sh must be executed from the root directory."
    exit 1
fi

find . -type f -name '*.sh' -print0 | xargs -0 shellcheck --external-sources

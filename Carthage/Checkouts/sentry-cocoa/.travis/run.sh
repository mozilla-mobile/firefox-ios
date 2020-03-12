#!/bin/bash
set -e

if [ "$LANE" = "lint" ]; then
    if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
        echo "We don't run linter for PRs, because Danger!"
        exit 0;
    fi
elif [ "$LANE" = "pod" ]; then
    pod repo update
fi

bundle exec fastlane $LANE

if [ "$LANE" = "test" ]; then
    bundle exec slather coverage --scheme Sentry && bash <(curl -s https://codecov.io/bash) -f cobertura.xml;
fi

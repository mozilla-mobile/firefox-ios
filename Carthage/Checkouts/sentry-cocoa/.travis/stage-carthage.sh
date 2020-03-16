#!/bin/sh

brew update > /dev/null
brew outdated carthage || brew upgrade carthage

carthage build --no-skip-current
carthage archive --output Sentry.framework.zip

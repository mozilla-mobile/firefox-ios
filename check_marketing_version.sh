#!/bin/bash

# Check if MARKETING_VERSION has changed
# The cut -d ' ' -f3 takes the output from grep command as input.
# For example, let's assume that the Common.xcconfig file contains the following line:
# MARKETING_VERSION = 100.2.44
# grep will return -> MARKETING_VERSION = 100.2.44
# The cut command will then extract the third field from the input, using a space (' ') as the delimiter.
# Output: 100.2.44

#!/bin/bash

# Get the current branch's MARKETING_VERSION
CURRENT_VERSION=$(grep 'MARKETING_VERSION' firefox-ios/Client/Configuration/Common.xcconfig | cut -d ' ' -f3)

if [ -n "$CIRCLECI" ]; then
  # CircleCI: Compare against the previous commit on the same branch
  echo "Running on CircleCI, checking against $CIRCLE_BRANCH~1"
  
  # Check if there is a previous commit available
  if git rev-parse "$CIRCLE_BRANCH~1" >/dev/null 2>&1; then
    OLD_VERSION=$(git show "$CIRCLE_BRANCH~1:firefox-ios/Client/Configuration/Common.xcconfig" | grep 'MARKETING_VERSION' | cut -d ' ' -f3)
  else
    echo "No previous commit found on $CIRCLE_BRANCH. Assuming the current version."
    OLD_VERSION=$CURRENT_VERSION
  fi

elif [ -n "$GITHUB_ACTIONS" ]; then
  # GitHub Actions: Compare against the main branch
  echo "Running on GitHub Actions, checking against the main branch"
  
  # Fetch the main branch
  git fetch origin main || { echo "Failed to fetch main branch"; exit 1; }

  # Get the MARKETING_VERSION from the main branch
  OLD_VERSION=$(git show origin/main:firefox-ios/Client/Configuration/Common.xcconfig | grep 'MARKETING_VERSION' | cut -d ' ' -f3)
  if [ $? -ne 0 ]; then
    echo "Failed to retrieve MARKETING_VERSION from main branch"
    exit 1
  fi
else
  echo "Not running in a CI environment. Exiting..."
  exit 0
fi

# Compare versions
if [ "$CURRENT_VERSION" = "$OLD_VERSION" ]; then
  echo "MARKETING_VERSION has not changed. Exiting..."

  # Detect CI environment and exit appropriately
  if [ -n "$CIRCLECI" ]; then
    circleci-agent step halt
  elif [ -n "$GITHUB_ACTIONS" ]; then
    echo "skipnext=true" >> $GITHUB_OUTPUT
  else
    exit 0
  fi
else
  echo "MARKETING_VERSION has changed from $OLD_VERSION to $CURRENT_VERSION"
  exit 0
fi
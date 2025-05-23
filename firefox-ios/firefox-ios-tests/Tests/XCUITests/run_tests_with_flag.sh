#!/bin/bash

# Usage: ./run_tests_with_flag.sh <jsonFileName> <featureName> <testPlanName>

if [[ $# -ne 3 ]]; then
  echo "❌ Error: Missing arguments."
  echo "Usage: $0 <jsonFileName> <featureName> <testPlanName>"
  echo "Example: $0 defaultEnabledOn tab-tray-ui-experiments fullfunctional"
  exit 1
fi

JSON_ARG="$1"
FEATURE_ARG="$2"
TEST_PLAN="$3"

SIMULATOR_ID="3D7295F7-FC2E-486E-B95C-57C66313A06B"  # Update if needed
SCHEME="Fennec"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS=$("$SCRIPT_DIR/find_test_with_flag.sh" "$JSON_ARG" "$FEATURE_ARG")

if [[ -z "$TESTS" ]]; then
  echo "⚠️ No matching tests found for: $JSON_ARG / $FEATURE_ARG"
  exit 0
fi

CMD=(xcodebuild test -scheme "$SCHEME" -testPlan "$TEST_PLAN" -destination "id=$SIMULATOR_ID")

while read -r test; do
  CMD+=("-only-testing:$test")
done <<< "$TESTS"

echo "Running tests with:"
echo "  JSON config     = $JSON_ARG"
echo "  Feature name    = $FEATURE_ARG"
echo "  Test plan       = $TEST_PLAN"
echo "  Simulator ID    = $SIMULATOR_ID"
echo ""
printf '%q ' "${CMD[@]}"
echo -e "\n"

"${CMD[@]}"
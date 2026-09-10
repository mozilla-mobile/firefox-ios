#!/bin/bash
#
# Runs only the XCUITests tagged with `// Regression` and produces a JUnit
# report plus a markdown summary, without adding a new test plan.
#
# It builds on FullFunctionalTestPlan because that is the plan which does not
# skip the Regression tests; the actual selection is the -only-testing list.
#
# Usage:
#   ./run_regression_tests.sh
#   ./run_regression_tests.sh -d 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
#   ./run_regression_tests.sh --shard 1/4 --skip-build
#
# Exit codes:
#   0   every test passed
#   70  infrastructure failure (build broke, run never started) -> no usable report
#   *   xcodebuild's own code: tests failed, but the report is valid

set -uo pipefail

EXIT_INFRA=70

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
PROJECT="$REPO_ROOT/firefox-ios/Client.xcodeproj"
PLAN_FILE="$REPO_ROOT/firefox-ios/firefox-ios-tests/Tests/FullFunctionalTestPlan.xctestplan"

SCHEME="Fennec"
TEST_PLAN="FullFunctionalTestPlan"
CONFIGURATION="Fennec_Testing"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 16,OS=latest}"
DERIVED_DATA="${DERIVED_DATA:-$REPO_ROOT/DerivedData}"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/test-reports}"
SHARD=""
SKIP_BUILD=0
RETRIES="${RETRIES:-0}"

usage() { sed -n '2,18p' "${BASH_SOURCE[0]}"; exit "${1:-0}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--destination) DESTINATION="$2"; shift 2 ;;
    -D|--derived-data) DERIVED_DATA="$2"; shift 2 ;;
    -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
    -s|--skip-build) SKIP_BUILD=1; shift ;;
    --shard) SHARD="$2"; shift 2 ;;
    --retries) RETRIES="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

mkdir -p "$OUTPUT_DIR"
SELECTION_JSON="$OUTPUT_DIR/regression-selection.json"
XCRESULT="$OUTPUT_DIR/regression.xcresult"
BUILD_LOG="$OUTPUT_DIR/build-for-testing.log"
TEST_LOG="$OUTPUT_DIR/test-without-building.log"

echo "==> Collecting // Regression tests"
SHARD_ARG=()
[[ -n "$SHARD" ]] && SHARD_ARG=(--shard "$SHARD")

# Empty arrays need the ${x[@]+...} guard: `set -u` on bash 3.2 (the /bin/bash
# shipped with macOS) treats expanding an empty array as an unbound variable.
"$SCRIPT_DIR/find_regression_tests.py" --plan "$PLAN_FILE" --format json \
  ${SHARD_ARG[@]+"${SHARD_ARG[@]}"} > "$SELECTION_JSON" || { echo "Collection failed" >&2; exit $EXIT_INFRA; }

ONLY_TESTING=()
while IFS= read -r line; do
  [[ -n "$line" ]] && ONLY_TESTING+=("-only-testing:$line")
done < <("$SCRIPT_DIR/find_regression_tests.py" --plan "$PLAN_FILE" --format plain \
           ${SHARD_ARG[@]+"${SHARD_ARG[@]}"} 2>/dev/null)

if [[ ${#ONLY_TESTING[@]} -eq 0 ]]; then
  echo "No runnable // Regression test found" >&2
  exit $EXIT_INFRA
fi
echo "==> ${#ONLY_TESTING[@]} tests selected | destination: $DESTINATION"

if [[ $SKIP_BUILD -eq 0 ]]; then
  echo "==> build-for-testing (log: $BUILD_LOG)"
  xcodebuild build-for-testing \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -testPlan "$TEST_PLAN" \
    -sdk iphonesimulator \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
    COMPILER_INDEX_STORE_ENABLE=NO \
    > "$BUILD_LOG" 2>&1
  BUILD_STATUS=$?
  if [[ $BUILD_STATUS -ne 0 ]]; then
    echo "build-for-testing failed (code $BUILD_STATUS). Last lines:" >&2
    tail -40 "$BUILD_LOG" >&2
    exit $EXIT_INFRA
  fi
fi

rm -rf "$XCRESULT"

RETRY_ARGS=()
if [[ "$RETRIES" -gt 0 ]]; then
  RETRY_ARGS=(-retry-tests-on-failure -test-iterations "$((RETRIES + 1))")
fi

echo "==> test-without-building (log: $TEST_LOG)"
xcodebuild test-without-building \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -testPlan "$TEST_PLAN" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$XCRESULT" \
  ${RETRY_ARGS[@]+"${RETRY_ARGS[@]}"} \
  "${ONLY_TESTING[@]}" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
  COMPILER_INDEX_STORE_ENABLE=NO \
  > "$TEST_LOG" 2>&1
TEST_STATUS=$?

if [[ ! -d "$XCRESULT" ]]; then
  echo "No .xcresult was produced; the run never started. Last lines:" >&2
  tail -40 "$TEST_LOG" >&2
  exit $EXIT_INFRA
fi

echo "==> Generating report"
"$SCRIPT_DIR/xcresult_to_junit.py" \
  --xcresult "$XCRESULT" \
  --junit "$OUTPUT_DIR/junit-regression.xml" \
  --summary "$OUTPUT_DIR/regression-summary.md" \
  --blocked-json "$SELECTION_JSON"
REPORT_STATUS=$?

# Code 3 = the bundle holds no test at all. Publishing an empty report as if it
# were a successful run would be a false green.
if [[ $REPORT_STATUS -eq 3 ]]; then
  echo "Empty report: no test was executed. Last lines:" >&2
  tail -40 "$TEST_LOG" >&2
  exit $EXIT_INFRA
fi

echo "==> Report in $OUTPUT_DIR (xcodebuild exited with $TEST_STATUS)"
exit $TEST_STATUS

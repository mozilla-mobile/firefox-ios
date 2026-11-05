#!/usr/bin/env bash
# Counts failed full functional tests across the shards of a Bitrise pipeline.
#
# Usage:
#   fullfunctional_failures.sh count   Run in a shard: writes the shard's failed test count to
#                                      $BITRISE_DEPLOY_DIR/fullfunctional_result.txt
#   fullfunctional_failures.sh sum     Run in the report: adds up the counts from
#                                      $FULLFUNCTIONAL_RESULT_0 .. $FULLFUNCTIONAL_RESULT_<n-1>
#                                      (n = $FULLFUNCTIONAL_SHARD_COUNT) and exports FAILED_TEST_COUNT

set -uo pipefail

count() {
    local failed_count
    if [ -z "${BITRISE_XCRESULT_PATH:-}" ]; then
        failed_count="no results"
    else
        failed_count=$(xcrun xcresulttool get --path "$BITRISE_XCRESULT_PATH" --format json --legacy 2>/dev/null \
            | jq -r '.metrics.testsFailedCount._value // 0')
    fi
    echo "Shard ${BITRISE_IO_PARALLEL_INDEX:-?} failures: ${failed_count:-no results}"
    echo "${failed_count:-no results}" > "$BITRISE_DEPLOY_DIR/fullfunctional_result.txt"
}

sum() {
    local total=0 details="" i result_file_var result_file shard_count
    shard_count="${FULLFUNCTIONAL_SHARD_COUNT:?FULLFUNCTIONAL_SHARD_COUNT is not set}"
    for i in $(seq 0 $((shard_count - 1))); do
        result_file_var="FULLFUNCTIONAL_RESULT_$i"
        result_file="${!result_file_var:-}"
        if [ -n "$result_file" ] && [ -f "$result_file" ]; then
            shard_failures=$(cat "$result_file")
        else
            shard_failures="no results"
        fi
        if [[ "$shard_failures" =~ ^[0-9]+$ ]]; then
            total=$((total + shard_failures))
        fi
        details="${details}Shard $((i + 1)): ${shard_failures}"$'\n'
    done
    echo "Total failures: $total"
    printf "%s" "$details"
    envman add --key FAILED_TEST_COUNT --value "$total"
}

case "${1:-}" in
    count) count ;;
    sum) sum ;;
    *) echo "Usage: $0 count|sum" >&2; exit 1 ;;
esac

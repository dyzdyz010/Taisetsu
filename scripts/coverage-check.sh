#!/bin/bash
set -euo pipefail

result_bundle="${1:-.build/TestResults.xcresult}"
minimum_coverage="${TAISETSU_CORE_COVERAGE_MINIMUM:-0.80}"

if [[ ! -d "${result_bundle}" ]]; then
    echo "Coverage result bundle not found: ${result_bundle}" >&2
    exit 1
fi

coverage_json=$(xcrun xccov view --report --json "${result_bundle}")
core_coverage=$(printf '%s' "${coverage_json}" | jq -r '
    [.targets[] | select(.name == "TaisetsuCore.framework") | .lineCoverage] | first // empty
')

if [[ -z "${core_coverage}" ]]; then
    echo "TaisetsuCore.framework coverage was not found." >&2
    exit 1
fi

printf 'TaisetsuCore line coverage: %.2f%% (minimum %.2f%%)\n' \
    "$(awk -v value="${core_coverage}" 'BEGIN { print value * 100 }')" \
    "$(awk -v value="${minimum_coverage}" 'BEGIN { print value * 100 }')"

awk -v actual="${core_coverage}" -v minimum="${minimum_coverage}" 'BEGIN { exit(actual < minimum) }'


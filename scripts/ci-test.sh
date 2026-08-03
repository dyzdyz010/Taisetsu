#!/bin/bash
set -euo pipefail

mkdir -p .build

if [[ -z "${LIFETIMER_SIMULATOR_UDID:-}" ]]; then
    LIFETIMER_SIMULATOR_UDID=$(xcrun simctl list devices available --json | jq -r '
        [.devices | to_entries[]
            | select(.key | contains("iOS"))
            | . as $runtime
            | .value[]
            | select(.name | startswith("iPhone"))
            | {runtime: $runtime.key, udid: .udid}]
        | sort_by(.runtime)
        | reverse
        | first
        | .udid
    ')
fi

if [[ -z "${LIFETIMER_SIMULATOR_UDID}" || "${LIFETIMER_SIMULATOR_UDID}" == "null" ]]; then
    echo "No available iPhone simulator was found." >&2
    exit 1
fi

result_bundle=".build/TestResults.xcresult"
if [[ -e "${result_bundle}" ]]; then
    rm -rf "${result_bundle}"
fi

test_selection=(-only-testing:LifeTimerTests)
if [[ "${LIFETIMER_INCLUDE_UI_TESTS:-0}" == "1" ]]; then
    test_selection=()
fi

xcodebuild test \
    -project LifeTimer.xcodeproj \
    -scheme LifeTimer \
    -destination "platform=iOS Simulator,id=${LIFETIMER_SIMULATOR_UDID}" \
    -parallel-testing-enabled NO \
    -enableCodeCoverage YES \
    -resultBundlePath "${result_bundle}" \
    "${test_selection[@]}" \
    "$@"


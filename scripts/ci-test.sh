#!/bin/bash
set -euo pipefail

mkdir -p .build

if [[ -z "${TAISETSU_SIMULATOR_UDID:-}" ]]; then
    TAISETSU_SIMULATOR_UDID=$(xcrun simctl list devices available --json | jq -r '
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

if [[ -z "${TAISETSU_SIMULATOR_UDID}" || "${TAISETSU_SIMULATOR_UDID}" == "null" ]]; then
    echo "No available iPhone simulator was found." >&2
    exit 1
fi

xcrun simctl boot "${TAISETSU_SIMULATOR_UDID}" 2>/dev/null || true
xcrun simctl bootstatus "${TAISETSU_SIMULATOR_UDID}" -b
xcrun simctl terminate "${TAISETSU_SIMULATOR_UDID}" com.dyz.Taisetsu 2>/dev/null || true

result_bundle=".build/TestResults.xcresult"
if [[ -e "${result_bundle}" ]]; then
    rm -rf "${result_bundle}"
fi

common_arguments=(
    test
    -project Taisetsu.xcodeproj
    -scheme Taisetsu
    -destination "platform=iOS Simulator,id=${TAISETSU_SIMULATOR_UDID}"
    -parallel-testing-enabled NO
    -enableCodeCoverage YES
    -resultBundlePath "${result_bundle}"
)

if [[ "${TAISETSU_INCLUDE_UI_TESTS:-0}" == "1" ]]; then
    xcodebuild "${common_arguments[@]}" "$@"
else
    xcodebuild "${common_arguments[@]}" -only-testing:TaisetsuTests "$@"
fi

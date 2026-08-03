#!/bin/bash
set -euo pipefail

for tool in xcodegen jq; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "Required tool is missing: ${tool}" >&2
        exit 1
    fi
done

xcodegen generate
git diff --exit-code -- LifeTimer.xcodeproj LifeTimer/Info.plist LifeTimer/LifeTimer.entitlements \
    LifeTimerWidget/Info.plist LifeTimerWidget/LifeTimerWidget.entitlements
xcrun swift-format lint --recursive LifeTimer LifeTimerCore LifeTimerWidget LifeTimerTests LifeTimerUITests
xcodebuild build \
    -project LifeTimer.xcodeproj \
    -scheme LifeTimer \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO
bash scripts/ci-test.sh
bash scripts/coverage-check.sh

if [[ "${LIFETIMER_INCLUDE_UI_TESTS:-0}" == "1" ]]; then
    LIFETIMER_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh \
        -only-testing:LifeTimerUITests/LifeTimerUITests/testCreatesAnAnniversaryFromTheEmptyState
fi


#!/bin/bash
set -euo pipefail

for tool in xcodegen jq; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "Required tool is missing: ${tool}" >&2
        exit 1
    fi
done

bash scripts/naming-check.sh
xcodegen generate
git diff --exit-code -- Taisetsu.xcodeproj Taisetsu/Info.plist Taisetsu/Taisetsu.entitlements \
    TaisetsuWidget/Info.plist TaisetsuWidget/TaisetsuWidget.entitlements
swift scripts/generate-localizations.swift --check
bash scripts/localization-check.sh
bash scripts/app-icon-check.sh
xcrun swift-format lint --recursive Taisetsu TaisetsuCore TaisetsuWidget TaisetsuTests TaisetsuUITests
xcodebuild build \
    -project Taisetsu.xcodeproj \
    -scheme Taisetsu \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO
bash scripts/ci-test.sh
bash scripts/coverage-check.sh

if [[ "${TAISETSU_INCLUDE_UI_TESTS:-0}" == "1" ]]; then
    TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh \
        -only-testing:TaisetsuUITests/TaisetsuUITests/testCreatesAnAnniversaryFromTheEmptyState \
        -only-testing:TaisetsuUITests/TaisetsuUITests/testEditorUsesDateWheelsAndStructuredRecurrenceControls \
        -only-testing:TaisetsuUITests/TaisetsuUITests/testLaunchesWithEnglishLocalization
fi

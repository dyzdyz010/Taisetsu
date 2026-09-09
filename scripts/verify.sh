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
    TaisetsuWidget/Info.plist TaisetsuWidget/TaisetsuWidget.entitlements \
    TaisetsuWatch/Info.plist TaisetsuWatch/TaisetsuWatch.entitlements \
    TaisetsuWatchWidget/Info.plist TaisetsuWatchWidget/TaisetsuWatchWidget.entitlements
bash scripts/localization-check.sh
bash scripts/app-icon-check.sh
xcrun swift-format lint --recursive Taisetsu TaisetsuCore TaisetsuWidget TaisetsuWatch \
    TaisetsuWatchWidget TaisetsuTests TaisetsuUITests

localization_catalogs=(
    Taisetsu/Resources/Localizable.xcstrings
    Taisetsu/Resources/InfoPlist.xcstrings
    TaisetsuWidget/Resources/Localizable.xcstrings
    TaisetsuWatch/Resources/Localizable.xcstrings
    TaisetsuWatchWidget/Resources/Localizable.xcstrings
)
taisetsu_catalog_checksums_before=$(shasum -a 256 "${localization_catalogs[@]}")

xcodebuild build \
    -project Taisetsu.xcodeproj \
    -scheme Taisetsu \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO

xcodebuild build \
    -project Taisetsu.xcodeproj \
    -scheme TaisetsuWatch \
    -destination 'generic/platform=watchOS Simulator' \
    CODE_SIGNING_ALLOWED=NO

taisetsu_catalog_checksums_after=$(shasum -a 256 "${localization_catalogs[@]}")
if [[ "${taisetsu_catalog_checksums_before}" != "${taisetsu_catalog_checksums_after}" ]]; then
    echo "Xcode extracted localization changes during the build. Update the checked-in String Catalogs." >&2
    exit 1
fi

bash scripts/ci-test.sh
bash scripts/coverage-check.sh

if [[ "${TAISETSU_INCLUDE_UI_TESTS:-0}" == "1" ]]; then
    TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh \
        -only-testing:TaisetsuUITests/TaisetsuUITests/testCreatesAnAnniversaryFromTheEmptyState \
        -only-testing:TaisetsuUITests/TaisetsuUITests/testDeletesAnAnniversaryFromEditorAfterConfirmation \
        -only-testing:TaisetsuUITests/TaisetsuUITests/testEditorUsesDateWheelsAndStructuredRecurrenceControls \
        -only-testing:TaisetsuUITests/TaisetsuUITests/testLaunchesWithEnglishLocalization \
        -only-testing:TaisetsuUITests/TaisetsuUITests/testCalendarSyncSettingsFollowSupportedLocales
fi

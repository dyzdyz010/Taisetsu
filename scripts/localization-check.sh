#!/bin/bash
set -euo pipefail

required_locales=(zh-Hans zh-Hant nb de)
default_catalogs=(
    Taisetsu/Resources/Localizable.xcstrings
    Taisetsu/Resources/InfoPlist.xcstrings
    TaisetsuWidget/Resources/Localizable.xcstrings
    TaisetsuWatch/Resources/Localizable.xcstrings
    TaisetsuWatchWidget/Resources/Localizable.xcstrings
)

if ! command -v jq >/dev/null 2>&1; then
    echo "Required tool is missing: jq" >&2
    exit 1
fi

catalogs=("${default_catalogs[@]}")
if [[ $# -gt 0 ]]; then
    catalogs=("$@")
fi

for catalog in "${catalogs[@]}"; do
    if [[ ! -f "${catalog}" ]]; then
        echo "Localization catalog is missing: ${catalog}" >&2
        exit 1
    fi

    if ! jq -e '
        .sourceLanguage == "en"
        and .version == "1.0"
        and (.strings | type == "object" and length > 0)
    ' "${catalog}" >/dev/null; then
        echo "Localization catalog metadata is invalid: ${catalog}" >&2
        exit 1
    fi

    if ! jq -e '
        [
            .strings
            | to_entries[]
            | select(.value.shouldTranslate != false)
            | select((.value.localizations | keys | sort) != ["de", "nb", "zh-Hans", "zh-Hant"])
        ]
        | length == 0
    ' "${catalog}" >/dev/null; then
        echo "Unsupported or missing locale in ${catalog}" >&2
        exit 1
    fi

    for locale in "${required_locales[@]}"; do
        if ! jq -e --arg locale "${locale}" '
            [
                .strings
                | to_entries[]
                | select(.value.shouldTranslate != false)
                | select(
                    .value.localizations[$locale].stringUnit.state != "translated"
                    or (.value.localizations[$locale].stringUnit.value | type != "string")
                    or (.value.localizations[$locale].stringUnit.value | length == 0)
                )
            ]
            | length == 0
        ' "${catalog}" >/dev/null; then
            echo "Missing or incomplete ${locale} translation in ${catalog}" >&2
            jq -r --arg locale "${locale}" '
                .strings
                | to_entries[]
                | select(.value.shouldTranslate != false)
                | select(
                    .value.localizations[$locale].stringUnit.state != "translated"
                    or (.value.localizations[$locale].stringUnit.value | type != "string")
                    or (.value.localizations[$locale].stringUnit.value | length == 0)
                )
                | "  - \(.key)"
            ' "${catalog}" >&2
            exit 1
        fi
    done

    if ! jq -e '
        def placeholders: [scan("%(?:[0-9]+\\$)?(?:@|lld|ld|d|f)")];
        [
            .strings
            | to_entries[] as $entry
            | ($entry.key | placeholders) as $source_placeholders
            | $entry.value.localizations
            | to_entries[]
            | select((.value.stringUnit.value | placeholders) != $source_placeholders)
        ]
        | length == 0
    ' "${catalog}" >/dev/null; then
        echo "A translation changed a format placeholder in ${catalog}" >&2
        exit 1
    fi

    if ! jq -e '
        def intentional_same($key; $locale):
            [
                "Countdown|de",
                "Minute: %lld|de",
                "Name|de",
                "Status|de",
                "Status|nb",
                "Tags|de",
                "Version|de",
                "Widgets|de"
            ]
            | index("\($key)|\($locale)") != null;
        [
            .strings
            | to_entries[] as $entry
            | $entry.value.localizations
            | to_entries[]
            | select(.value.stringUnit.value == $entry.key)
            | select(intentional_same($entry.key; .key) | not)
        ]
        | length == 0
    ' "${catalog}" >/dev/null; then
        echo "A translation unexpectedly matches its English source in ${catalog}" >&2
        exit 1
    fi
done

if [[ "$(plutil -extract CFBundleDisplayName raw Taisetsu/Info.plist)" != "Taisetsu" ]]; then
    echo "Base app display name must remain Taisetsu" >&2
    exit 1
fi

if ! jq -e '
    .strings.CFBundleDisplayName.localizations as $names
    | $names["zh-Hans"].stringUnit.value == "重要日"
      and $names["zh-Hant"].stringUnit.value == "重要日"
      and (["nb", "de"]
        | map($names[.].stringUnit.value == "Taisetsu")
        | all)
' Taisetsu/Resources/InfoPlist.xcstrings >/dev/null; then
    echo "App display-name localization contract is invalid" >&2
    exit 1
fi

echo "Localization catalogs are complete for English plus ${#required_locales[@]} translated locales."

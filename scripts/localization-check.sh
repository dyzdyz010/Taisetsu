#!/bin/bash
set -euo pipefail

required_locales=(zh-Hans zh-Hant ja ko es fr de pt-BR it ar)
default_catalogs=(
    Taisetsu/Resources/Localizable.xcstrings
    Taisetsu/Resources/InfoPlist.xcstrings
    TaisetsuWidget/Resources/Localizable.xcstrings
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
done

echo "Localization catalogs are complete for ${#required_locales[@]} translated locales."

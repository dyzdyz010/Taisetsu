#!/bin/bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repository_root}"

icon_directory="Taisetsu/Assets.xcassets/AppIcon.appiconset"
contents_path="${icon_directory}/Contents.json"
svg_path="Design/AppIcon/TaisetsuAppIcon.svg"
icon_files=(
    "AppIcon.png"
    "AppIcon-Dark.png"
    "AppIcon-Tinted.png"
)

for icon_file in "${icon_files[@]}"; do
    icon_path="${icon_directory}/${icon_file}"
    if [[ ! -f "${icon_path}" ]]; then
        echo "Missing app icon asset: ${icon_file}" >&2
        exit 1
    fi

    properties="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "${icon_path}" 2>/dev/null)"
    width="$(awk '/pixelWidth:/ { print $2 }' <<<"${properties}")"
    height="$(awk '/pixelHeight:/ { print $2 }' <<<"${properties}")"
    has_alpha="$(awk '/hasAlpha:/ { print $2 }' <<<"${properties}")"

    if [[ "${width}" != "1024" || "${height}" != "1024" ]]; then
        echo "App icon asset must be 1024x1024: ${icon_file}" >&2
        exit 1
    fi

    if [[ "${has_alpha}" != "no" ]]; then
        echo "App icon asset must not contain an alpha channel: ${icon_file}" >&2
        exit 1
    fi
done

if ! jq -e '
    (.images | length == 3) and
    (.images | map(select(.appearances == null))[0].filename == "AppIcon.png") and
    (.images | map(select(.appearances[0].value == "dark"))[0].filename == "AppIcon-Dark.png") and
    (.images | map(select(.appearances[0].value == "tinted"))[0].filename == "AppIcon-Tinted.png")
' "${contents_path}" >/dev/null; then
    echo "App icon appearances are not assigned to the approved files" >&2
    exit 1
fi

if [[ ! -f "${svg_path}" ]]; then
    echo "Missing app icon vector master: ${svg_path}" >&2
    exit 1
fi

swift scripts/generate-app-icon.swift --check
echo "App icon assets are complete and current."

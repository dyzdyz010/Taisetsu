#!/bin/bash
set -euo pipefail

legacy_compound='Life''Timer'
legacy_lower='life''timer'
legacy_spaced='Life'' Timer'
legacy_chinese='生命''倒计时'
patterns=("${legacy_compound}" "${legacy_lower}" "${legacy_spaced}" "${legacy_chinese}")
failed=0

for pattern in "${patterns[@]}"; do
    path_matches=$(git ls-files | grep -iF "${pattern}" || true)
    content_matches=$(git grep -I -n -i -F "${pattern}" -- . || true)
    if [[ -n "${path_matches}" || -n "${content_matches}" ]]; then
        printf 'Forbidden legacy alias: %s\n' "${pattern}" >&2
        [[ -z "${path_matches}" ]] || printf '%s\n' "${path_matches}" >&2
        [[ -z "${content_matches}" ]] || printf '%s\n' "${content_matches}" >&2
        failed=1
    fi
done

exit "${failed}"

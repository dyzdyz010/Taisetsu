# Taisetsu Brand and Localization Guide

## Brand contract

The public product name is **Taisetsu** in every language. It is a brand word, not a translatable string and not an alternate spelling of the Japanese adjective.

- English descriptor: **Important Days**
- English brand line: **Keep the days that matter close.**
- Simplified Chinese descriptor: **重要日**
- Simplified Chinese brand line: **把重要的日子，放在心上。**

Descriptors and brand lines may be localized. `Taisetsu` must remain unchanged in the app name, navigation title, widget name, exported-calendar attribution, screenshots, and store metadata.

## Technical identity contract

Public branding and technical identity are unified under `Taisetsu`:

- GitHub repository, Xcode project, targets, schemes, and Swift modules beginning with `Taisetsu`
- bundle identifiers `com.dyz.Taisetsu`, `com.dyz.TaisetsuCore`, and `com.dyz.Taisetsu.Widget`
- App Group `group.com.dyz.Taisetsu`
- CloudKit container `iCloud.com.dyz.Taisetsu`
- widget kind `TaisetsuUpcoming`, notification prefix `taisetsu.`, and URL scheme `taisetsu://`

These values define a new application identity. The identity reset did not migrate data from earlier development builds. Any future identifier change requires an explicit migration design covering installed data, widgets, notifications, calendar-export links, deep links, and private iCloud records.

## Launch locales

English is the development language and fallback. The first release supports:

| Language | Locale |
| --- | --- |
| English | `en` |
| Simplified Chinese | `zh-Hans` |
| Traditional Chinese | `zh-Hant` |
| Japanese | `ja` |
| Korean | `ko` |
| Spanish | `es` |
| French | `fr` |
| German | `de` |
| Brazilian Portuguese | `pt-BR` |
| Italian | `it` |
| Arabic | `ar` |

Arabic must remain usable with the system's right-to-left layout. Date-wheel order, weekday order, dates, relative time, list joining, recurrence intervals, and reminder offsets come from the active `Locale` and `Calendar`; do not assemble them from English fragments.

## Catalog ownership

- `Taisetsu/Resources/Localizable.xcstrings`: app, validation, notification, accessibility, and calendar-export copy
- `Taisetsu/Resources/InfoPlist.xcstrings`: permission copy
- `TaisetsuWidget/Resources/Localizable.xcstrings`: widget UI and configuration copy
- `scripts/generate-localizations.swift`: authoritative catalog content and deterministic generator

User-created names, notes, categories, and tags are data and are never translated. The five built-in categories have stable IDs and resolve to localized display names without changing their stored records.

## Update workflow

1. Add or change the English source key and every translation in `scripts/generate-localizations.swift`.
2. Regenerate catalogs with `swift scripts/generate-localizations.swift`.
3. Run `bash scripts/localization-check.sh`.
4. Run `bash scripts/verify.sh` before committing.

CI runs the generator in `--check` mode and rejects missing or empty translations for any launch locale. This makes source-controlled catalogs deterministic and prevents a newly added string from silently shipping in English only.

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
- bundle identifiers `com.dyz.Taisetsu`, `com.dyz.TaisetsuCore`, `com.dyz.Taisetsu.Widget`,
  `com.dyz.Taisetsu.watchkitapp`, and `com.dyz.Taisetsu.watchkitapp.Widget`
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
| Norwegian Bokmål | `nb` |
| German | `de` |

Date-wheel order, weekday order, dates, relative time, list joining, recurrence intervals, and reminder offsets come from the active `Locale` and `Calendar`; do not assemble them from English fragments.

## Catalog ownership

- `Taisetsu/Resources/Localizable.xcstrings`: app, validation, notification, accessibility, and calendar-export copy
- `Taisetsu/Resources/InfoPlist.xcstrings`: localized display name and permission copy
- `TaisetsuWidget/Resources/Localizable.xcstrings`: widget UI and configuration copy

These checked-in String Catalogs are the authoritative translation source. Do not maintain a second generated translation table.

User-created names, notes, categories, and tags are data and are never translated. The five built-in categories have stable IDs and resolve to localized display names without changing their stored records.

## Update workflow

1. Add or change the English source key and all four translations directly in the owning String Catalog.
2. Run `bash scripts/localization-check.sh`.
3. Run `bash scripts/verify.sh` before committing.

CI rejects missing, empty, unsupported, or accidental English-placeholder translations. It also compares catalog checksums around the Xcode build so newly extracted strings cannot silently ship without review.

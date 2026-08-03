# Taisetsu Brand and Internationalization Design

**Date:** 2026-08-03

**Status:** Localization direction approved; technical identity superseded by the total rename design

**Brand direction:** Warm, restrained, calm

## Brand decision

The public product name is **Taisetsu**. The name is invariant across locales and is never translated. The later [total technical rename design](2026-08-03-taisetsu-total-rename-design.md) made `Taisetsu` the repository's public and technical identity and intentionally created a new application identity without migrating earlier development data.

The global English descriptor is **Important Days** and the English brand line is **Keep the days that matter close.** Chinese-facing metadata uses **重要日** and **把重要的日子，放在心上。** These descriptors are localized copy, not alternate product names.

## Localization scope

The first international release supports these locales:

| Locale | Language |
| --- | --- |
| `en` | English and global fallback |
| `zh-Hans` | Simplified Chinese |
| `zh-Hant` | Traditional Chinese |
| `ja` | Japanese |
| `ko` | Korean |
| `es` | Spanish |
| `fr` | French |
| `de` | German |
| `pt-BR` | Brazilian Portuguese |
| `it` | Italian |
| `ar` | Arabic |

English is the development language. All user-visible app, widget, notification, calendar-export, validation, permission, and accessibility copy must be localizable. User-created names and tags are never translated.

## Locale-aware behavior

- Dates and times use Foundation format styles with the active locale and time zone.
- The three date wheels remain year, month, and day controls, but their visual order follows the locale's short-date order.
- Calendar weekday headings rotate to the locale/calendar first weekday.
- Relative day counts and recurring intervals use localized Foundation formatting so singular and plural grammar is not assembled from English fragments.
- SwiftUI provides right-to-left layout mirroring for Arabic; custom rows must not force left-to-right alignment.
- Built-in category IDs remain stable. Their visible names are resolved at display/mapping time, so changing the device language updates them without rewriting user data.
- Widget copy and configuration metadata have their own localization catalog because the widget is a separate bundle.

## Branding in the product

- Home navigation title and app display name: `Taisetsu`
- Widget display name: localized equivalent of `Taisetsu — Important Days`
- Calendar export source note: localized equivalent of `Created with Taisetsu`
- Technical identifiers follow the exact values in the total technical rename design.

## Quality gates

- Unit tests cover locale-sensitive date-wheel ordering, weekday rotation, built-in category names, relative/recurrence formatting, notification copy, and calendar export attribution.
- A localization validation script fails when required locales or translated string units are missing.
- UI tests explicitly launch in Simplified Chinese and English instead of depending on the CI machine language.
- CI runs localization validation before build and tests.

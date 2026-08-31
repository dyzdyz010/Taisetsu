# Taisetsu Five-Locale Internationalization Design

**Date:** 2026-08-31

**Status:** Approved

## Goal

Eliminate mixed-language UI and establish one enforceable localization contract for every user-visible surface in Taisetsu. The shipped product supports English, Simplified Chinese, Traditional Chinese, Norwegian Bokmål, and German only.

## Supported locales

| Locale | Language | Role |
| --- | --- | --- |
| `en` | English | Development language and final fallback |
| `zh-Hans` | Simplified Chinese | Complete translation |
| `zh-Hant` | Traditional Chinese | Complete translation |
| `nb` | Norwegian Bokmål | Complete translation |
| `de` | German | Complete translation |

No other locale is part of the product contract. Japanese, Korean, Spanish, French, Brazilian Portuguese, Italian, and Arabic must be removed from the application, widget, and Info.plist catalogs, Xcode known regions, validation scripts, tests, and documentation that describes the current release scope.

The application icon display name remains `重要日` for `zh-Hans` and `zh-Hant`. It remains `Taisetsu` for `en`, `nb`, and `de`. The technical product name and identifiers remain `Taisetsu` in every locale.

## Root causes

The calendar auto-sync feature introduced three distinct localization failures:

1. Several newly added translations used the English source text as a placeholder in non-English locales.
2. Runtime `String` expressions, including conditional status and button values, bypass SwiftUI's localized string literal handling even when translations exist in the catalog.
3. Newly extracted strings such as calendar-sync scope choices were not reconciled into the maintained catalogs, so Xcode's extracted catalog state drifted from the checked-in translations.

The existing validation checks that translations are present, but it accepts accidental English placeholders and does not prove that runtime values resolve through localization.

## String architecture

### Catalog ownership

The checked-in application, widget, and Info.plist `.xcstrings` files are the canonical translation source. The previous custom generator is retired so Xcode, CI, and translators no longer maintain a generated copy of the same data.

Each translatable key must provide exactly the four non-source translations: `zh-Hans`, `zh-Hant`, `nb`, and `de`. English remains the catalog source language and does not need a duplicated translation entry.

English source phrases remain catalog keys. This matches the existing SwiftUI literal-based code and avoids a risky migration of the entire product to opaque semantic identifiers. Ambiguous or context-sensitive strings receive translator comments in the generated catalog.

### Static and dynamic strings

Static SwiftUI text uses string literals so SwiftUI resolves `LocalizedStringKey` automatically. User-visible content created as a runtime `String` must be localized explicitly before presentation.

Conditional presentation must not pass a ternary `String` directly to `Text`, `Label`, `Button`, `LabeledContent`, navigation titles, accessibility modifiers, or alerts. It must instead choose between localized view branches or resolve through the shared localization API.

Application services, validation errors, notifications, and exported calendar metadata use `AppLocalization` because they produce `String` values outside SwiftUI. The localization API must support explicit locale injection for deterministic tests and use English as the fallback when an unsupported locale is requested.

User-created titles, category names, tag names, and notes are data, not interface copy, and are never translated. Stable built-in categories continue resolving localized display names at presentation time.

### Structured values

Dates, times, lists, relative dates, recurrence intervals, and numeric values use Foundation formatters with the active locale. Quantities such as a sync horizon must not concatenate an English unit. They use locale-aware `DateComponentsFormatter` output or String Catalog plural variation when surrounding copy requires a sentence.

Brand names, system identifiers, SF Symbol names, persistence raw values, URLs, file names, and calendar identifiers are not translated. System or framework errors may use their own localized descriptions; every app-owned error and recovery message must come from the application catalog.

## Catalog scope

The audit covers all user-visible surfaces:

- Application navigation, settings, editors, detail views, empty states, filters, dialogs, and accessibility labels
- Calendar auto-sync prompt, settings, state values, scope options, errors, and confirmation messages
- Widget names, descriptions, empty states, pinned indicators, previews, and relative dates
- Notification titles and bodies
- Exported system-calendar notes and app-created calendar labels where localization is appropriate
- Info.plist privacy usage descriptions and localized display names

Source files are audited for both static localization literals and runtime strings. New keys extracted by Xcode must be translated in the canonical catalogs before the change is accepted.

## Translation rules

Translations must be natural interface copy, not word-for-word substitutions. The five locale variants must preserve product meaning, placeholders, punctuation intent, and platform terminology. An English-identical translation is allowed only when the target language convention genuinely uses the same term and the key-locale pair is explicitly documented in a narrow allowlist.

Format placeholders must match the source key exactly. Interpolated user content must remain an argument rather than being embedded into a translated key. Translators receive comments where a short term can have multiple meanings, including synchronization state, calendar scope, pinning state, and count style.

## Validation and testing

The String Catalogs and validation script form the structural quality gate. CI must fail for:

- Missing, empty, or non-translated units for any supported non-source locale
- Any localization outside `zh-Hans`, `zh-Hant`, `nb`, and `de`
- Placeholder type or ordering changes
- English-identical target strings not present in the intentional allowlist
- An invalid localized application display-name contract
- A build changing a checked-in catalog through automatic source extraction

Unit tests cover explicit lookup for all five locales, unsupported-locale fallback to English, conditional status and action labels, sync-horizon quantity formatting, date/time formatting, app-owned errors, built-in category names, notifications, and calendar-export attribution.

UI tests launch the application with `en`, `zh-Hans`, `zh-Hant`, `nb`, and `de`. The calendar-sync settings flow verifies localized navigation, section titles, status values, range text, and scope choices. Existing creation and editor tests continue using stable accessibility identifiers where interaction does not depend on translated copy.

Final verification runs catalog validation, build-time extraction drift detection, formatting lint, unit tests, UI localization smoke tests when the simulator is available, and an unsigned simulator build. If the environment cannot run simulator tests, that limitation is reported separately and does not weaken the catalog and unit-test requirements.

## Existing worktree changes

The worktree already contains uncommitted Xcode project and String Catalog changes. Implementation must preserve unrelated project configuration changes. Newly auto-extracted catalog keys are reconciled directly into the canonical catalogs. The untracked development certificate is outside the task and must not be read, modified, staged, or committed.

## Acceptance criteria

- Chinese, English, Norwegian Bokmal, and German screens never mix app-owned English copy into a non-English locale.
- Simplified and Traditional Chinese remain distinct complete locale variants.
- Only the five approved locales appear as supported regions.
- Calendar-sync status, actions, range, scope, prompt, detail state, errors, and permission text are localized.
- App, widget, notification, calendar-export, accessibility, and Info.plist strings satisfy the same contract.
- Dynamic values and quantity formatting follow the active locale rather than relying on SwiftUI literal inference.
- CI prevents missing translations, accidental English placeholders, unsupported locales, and extraction drift from returning.
- All available verification steps pass, with any unavailable simulator-only evidence disclosed explicitly.

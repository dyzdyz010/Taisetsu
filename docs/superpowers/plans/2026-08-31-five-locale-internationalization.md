# Five-Locale Internationalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove mixed-language UI and enforce complete English, Simplified Chinese, Traditional Chinese, Norwegian Bokmål, and German localization across the app and widget.

**Architecture:** Keep the existing English-source-key String Catalog design and make the checked-in catalogs the single editable translation source. SwiftUI owns static literal lookup, `AppLocalization` owns runtime string and locale-aware value formatting outside that path, and CI compares catalog checksums around the build to catch extraction drift.

**Tech Stack:** Swift 6, SwiftUI, Foundation localization APIs, Xcode String Catalogs, Swift Testing, XCTest, Bash, jq, XcodeGen

**Spec:** `docs/superpowers/specs/2026-08-31-five-locale-internationalization-design.md`

## Global Constraints

- Supported locales are exactly `en`, `zh-Hans`, `zh-Hant`, `nb`, and `de`.
- English is the development language and final fallback.
- The localized app display name is `重要日` for both Chinese variants and `Taisetsu` for English, Norwegian Bokmål, and German.
- User-created titles, category names, tags, and notes are never translated.
- Preserve all unrelated worktree changes and never read, stage, modify, or commit `APPLE_DEVELOPMENT_CERTIFICATE.p12`.
- The environment exposes `.git` read-only, so implementation records verification without staging or committing.

---

### Task 1: Lock the five-locale runtime contract with failing tests

**Files:**
- Modify: `TaisetsuTests/AppLocalizationTests.swift`

**Interfaces:**
- Consumes: `AppLocalization.string(_:locale:)` and `AppLocalization.yearDuration(_:locale:)`.
- Produces: regression coverage for locale lookup, English fallback, calendar-sync copy, and localized year quantities.

- [ ] **Step 1: Add failing lookup tests**

Add table-driven assertions with literal expected values:

```swift
@Test func calendarSyncCopyResolvesInEverySupportedLocale() {
    let cases = [
        ("en_US", "Calendar Sync", "Enabled"),
        ("zh_Hans_CN", "日历同步", "已启用"),
        ("zh_Hant_TW", "行事曆同步", "已啟用"),
        ("nb_NO", "Kalendersynkronisering", "Aktivert"),
        ("de_DE", "Kalendersynchronisierung", "Aktiviert"),
    ]
    for (identifier, title, status) in cases {
        let locale = Locale(identifier: identifier)
        #expect(AppLocalization.string("Calendar Sync", locale: locale) == title)
        #expect(AppLocalization.string("Enabled", locale: locale) == status)
    }
}

@Test func unsupportedLocalesFallBackToEnglish() {
    #expect(AppLocalization.string("Calendar Sync", locale: Locale(identifier: "fr_FR")) == "Calendar Sync")
}
```

- [ ] **Step 2: Add a failing localized-duration test**

```swift
@Test func syncHorizonUsesLocaleAwareYearUnits() {
    #expect(AppLocalization.yearDuration(2, locale: Locale(identifier: "en_US")) == "2 years")
    #expect(AppLocalization.yearDuration(2, locale: Locale(identifier: "zh_Hans_CN")) == "2年")
    #expect(AppLocalization.yearDuration(2, locale: Locale(identifier: "zh_Hant_TW")) == "2年")
    #expect(AppLocalization.yearDuration(2, locale: Locale(identifier: "nb_NO")) == "2 år")
    #expect(AppLocalization.yearDuration(2, locale: Locale(identifier: "de_DE")) == "2 Jahre")
}
```

- [ ] **Step 3: Run focused tests and verify RED**

Run:

```bash
bash scripts/ci-test.sh -only-testing:TaisetsuTests/AppLocalizationTests
```

Expected: Norwegian lookups fail and `yearDuration` is unavailable.

### Task 2: Make String Catalogs a strict five-locale SSOT

**Files:**
- Delete: `scripts/generate-localizations.swift`
- Modify: `scripts/localization-check.sh`
- Modify: `scripts/verify.sh`
- Regenerate: `Taisetsu/Resources/Localizable.xcstrings`
- Regenerate: `Taisetsu/Resources/InfoPlist.xcstrings`
- Regenerate: `TaisetsuWidget/Resources/Localizable.xcstrings`

**Interfaces:**
- Produces: canonical catalogs containing only `zh-Hans`, `zh-Hant`, `nb`, and `de` translation units under English source keys.
- Consumes: Xcode's source extraction and the exact supported-locale array.

- [ ] **Step 1: Complete the five-locale catalogs**

Retain the existing Simplified Chinese, Traditional Chinese, and German translations. Remove Japanese, Korean, Spanish, French, Brazilian Portuguese, Italian, and Arabic and add one natural Norwegian Bokmål translation for every app, widget, and Info.plist entry.

Calendar-sync terminology uses this consistent glossary:

| English key | `zh-Hans` | `zh-Hant` | `nb` | `de` |
| --- | --- | --- | --- | --- |
| Calendar Sync | 日历同步 | 行事曆同步 | Kalendersynkronisering | Kalendersynchronisierung |
| Automatic Sync | 自动同步 | 自動同步 | Automatisk synkronisering | Automatische Synchronisierung |
| Enabled | 已启用 | 已啟用 | Aktivert | Aktiviert |
| Stopped | 已停止 | 已停止 | Stoppet | Gestoppt |
| Managed Events | 托管事件 | 管理事件 | Administrerte hendelser | Verwaltete Ereignisse |
| Last Synced | 上次同步 | 上次同步 | Sist synkronisert | Zuletzt synchronisiert |
| Sync Range | 同步范围 | 同步範圍 | Synkroniseringsperiode | Synchronisierungszeitraum |
| Scope | 范围 | 範圍 | Omfang | Umfang |
| Records | 重要日 | 重要日 | Viktige dager | Wichtige Tage |
| All Important Days | 所有重要日 | 所有重要日 | Alle viktige dager | Alle wichtigen Tage |
| Custom | 自定义 | 自訂 | Tilpasset | Benutzerdefiniert |

Add all calendar-sync keys missing from the catalog, including `Scope`, `Records`, `All Important Days`, `Custom`, and app-owned calendar error copy. Mark maintained entries as manual so Xcode does not rewrite their extraction state while still allowing truly new literals to appear as catalog drift.

- [ ] **Step 2: Tighten catalog validation**

Change `required_locales` to `zh-Hans zh-Hant nb de`. For every translatable entry, require the localization key set to equal those four locales, require translated state and a non-empty value, and preserve placeholder validation. Add a narrow `key|locale` allowlist for target text that legitimately equals its English key; reject every other identical English target value.

- [ ] **Step 3: Retire duplicate generation and validate catalogs**

Run:

```bash
bash scripts/localization-check.sh
```

Delete `scripts/generate-localizations.swift` and remove its calls from verification. Expected: all three canonical catalogs contain exactly four translated locale entries per translatable key and validation passes.

- [ ] **Step 4: Detect post-extraction drift**

Record checksums for all three catalogs in `scripts/verify.sh` before `xcodebuild build` and compare them immediately afterward. This catches a SwiftUI literal that Xcode extracted but the canonical catalogs do not own.

### Task 3: Fix runtime localization boundaries in calendar-sync UI

**Files:**
- Modify: `Taisetsu/Shared/AppLocalization.swift`
- Modify: `Taisetsu/Features/Settings/SettingsView.swift`
- Modify: `Taisetsu/Coordination/CalendarSyncPromptCoordinator.swift`
- Modify: `Taisetsu/Features/Detail/AnniversaryDetailView.swift`

**Interfaces:**
- Produces: `AppLocalization.yearDuration(_:locale:) -> String` and explicit localization of runtime calendar-sync values.
- Consumes: SwiftUI's environment locale and the catalog keys from Task 2.

- [ ] **Step 1: Implement locale-aware year duration**

Add:

```swift
static func yearDuration(_ years: Int, locale: Locale = .current) -> String {
    var components = DateComponents()
    components.year = years
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = .year
    formatter.unitsStyle = .full
    formatter.maximumUnitCount = 1
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = locale
    formatter.calendar = calendar
    return formatter.string(from: components) ?? String(years)
}
```

- [ ] **Step 2: Localize Settings runtime values explicitly**

Read `@Environment(\.locale)` in `CalendarSyncSettingsView`. Resolve `Enabled`, `Stopped`, `Stop Automatic Sync`, and `Enable Automatic Sync` through `AppLocalization.string(_:locale:)`. Present the status and action using those localized values, and replace the English `"\(years) years"` fragment with `AppLocalization.yearDuration`.

Static literals remain SwiftUI literals. User category and tag values remain unchanged.

- [ ] **Step 3: Audit adjacent sync surfaces**

Keep static prompt and detail literals on SwiftUI's localized path. Ensure any runtime confirmation or app-owned error uses `AppLocalization`, while `record.title`, `tag.name`, `record.notes`, and system-provided localized errors remain data.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run:

```bash
bash scripts/ci-test.sh -only-testing:TaisetsuTests/AppLocalizationTests
```

Expected: all `AppLocalizationTests` pass.

### Task 4: Verify localized settings behavior in UI tests

**Files:**
- Modify: `TaisetsuUITests/TaisetsuUITests.swift`

**Interfaces:**
- Consumes: stable tab/navigation accessibility identifiers and locale launch arguments.
- Produces: five-locale calendar-sync smoke coverage.

- [ ] **Step 1: Add one table-driven UI smoke helper**

Add a helper that launches with language and locale arguments, opens Settings and Calendar Sync, and asserts the localized navigation title plus status text. Use this literal matrix:

```swift
let cases = [
    ("en", "en_US", "Settings", "Calendar Sync", "Stopped"),
    ("zh-Hans", "zh_CN", "设置", "日历同步", "已停止"),
    ("zh-Hant", "zh_TW", "設定", "行事曆同步", "已停止"),
    ("nb", "nb_NO", "Innstillinger", "Kalendersynkronisering", "Stoppet"),
    ("de", "de_DE", "Einstellungen", "Kalendersynchronisierung", "Gestoppt"),
]
```

Use existing or newly added stable accessibility identifiers to navigate; translated labels are assertions, not selectors for intermediate actions.

- [ ] **Step 2: Run UI localization smoke tests**

Run:

```bash
TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh -only-testing:TaisetsuUITests/TaisetsuUITests/testCalendarSyncSettingsFollowSupportedLocales
```

Expected: five subcases pass when the simulator service is available. If it is unavailable, retain the test and report the environment limitation.

### Task 5: Align project documentation and complete verification

**Files:**
- Modify: `docs/brand-localization.md`
- Modify: `docs/superpowers/specs/2026-08-03-taisetsu-brand-internationalization-design.md`
- Modify: `docs/superpowers/plans/2026-08-03-taisetsu-internationalization.md`

**Interfaces:**
- Produces: current documentation that names only the five supported locales while preserving historical context where explicitly marked historical.

- [ ] **Step 1: Update current locale documentation**

Replace the eleven-locale release contract with `en`, `zh-Hans`, `zh-Hant`, `nb`, and `de`. Mark the older implementation plan as superseded by the 2026-08-31 design rather than rewriting its historical execution steps.

- [ ] **Step 2: Run full non-UI verification**

Run:

```bash
bash scripts/localization-check.sh
xcrun swift-format lint --recursive Taisetsu TaisetsuCore TaisetsuWidget TaisetsuTests TaisetsuUITests
xcodebuild build -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
bash scripts/ci-test.sh
```

Expected: every command exits zero with no localization drift.

- [ ] **Step 3: Inspect the final diff**

Confirm that only internationalization source, generated catalogs, targeted tests, and current localization documentation changed. Confirm that `APPLE_DEVELOPMENT_CERTIFICATE.p12` remains untracked and untouched and that unrelated project settings remain unchanged.

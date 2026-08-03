# Taisetsu Internationalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand the shipped product as Taisetsu and make every user-visible app, widget, notification, permission, and date presentation path locale-aware in eleven launch locales.

**Architecture:** Preserve all `LifeTimer` technical identifiers for data compatibility while changing only public branding. Keep static copy in per-bundle Xcode String Catalogs, centralize dynamic localized text in small formatter types, and derive date/calendar layout from the active locale. Resolve stable built-in category IDs to localized display names at read time so language changes do not mutate persistence.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, WidgetKit, Foundation localization APIs, Xcode String Catalogs, Swift Testing, XCTest, XcodeGen, Bash/JQ, GitHub Actions

## Global Constraints

- Public product name is exactly `Taisetsu` in every locale.
- Keep existing bundle IDs, App Group, CloudKit container, widget kind, URL scheme, persistence schema names, and Swift target/module names unchanged.
- Support `en`, `zh-Hans`, `zh-Hant`, `ja`, `ko`, `es`, `fr`, `de`, `pt-BR`, `it`, and `ar`.
- English is the development language and global fallback.
- Keep all three widget families: small square, medium rectangle, and large square.
- Keep the editor's three wheel controls; order them using the active locale.
- Recurrence remains an explicit “Every + quantity + unit” structure.
- Work directly on `main` and push without creating a pull request, as explicitly requested.

---

### Task 1: Locale-aware formatting primitives

**Files:**
- Create: `LifeTimer/Shared/AppLocalization.swift`
- Modify: `LifeTimer/Shared/AnniversaryFormatters.swift`
- Modify: `LifeTimer/Features/Editor/DateRuleSection.swift`
- Modify: `LifeTimer/Features/Calendar/CalendarView.swift`
- Create: `LifeTimerTests/AppLocalizationTests.swift`

**Interfaces:**
- Produces: `AppLocalization.string(_:locale:)`, `AnniversaryFormatters.relative(_:mode:now:locale:calendar:)`, `AnniversaryFormatters.recurrence(_:locale:)`, `DateWheelComponent.ordered(for:)`, and `LocalizedCalendarLayout.weekdaySymbols(for:)`.
- Consumes: Foundation locale, calendar, date-format, and relative-date formatting APIs.

- [ ] **Step 1: Write failing formatter tests**

Add tests asserting that English and Simplified Chinese relative/recurrence output is localized, `en_US` orders wheels month-day-year, `zh_CN` orders year-month-day, and a Monday-first calendar rotates weekday symbols to Monday first.

- [ ] **Step 2: Run the focused tests and verify RED**

Run: `bash scripts/ci-test.sh -only-testing:LifeTimerTests/AppLocalizationTests`

Expected: compilation fails because the formatter/layout interfaces do not exist.

- [ ] **Step 3: Implement the minimal locale-aware primitives**

Use `RelativeDateTimeFormatter` for relative day copy, `DateComponentsFormatter` plus a localized recurrence template for intervals, `DateFormatter.dateFormat(fromTemplate:options:locale:)` to order `y/M/d`, and a rotation based on `Calendar.firstWeekday` for weekday headings.

- [ ] **Step 4: Use the primitives in date wheels and calendar UI**

Render each wheel through `ForEach(DateWheelComponent.ordered(for: Locale.current))`, keep the existing wheel accessibility identifiers, remove Chinese suffixes from raw number labels, and use rotated weekday symbols in `CalendarView`.

- [ ] **Step 5: Run the focused tests and verify GREEN**

Run: `bash scripts/ci-test.sh -only-testing:LifeTimerTests/AppLocalizationTests`

Expected: all `AppLocalizationTests` pass.

### Task 2: Localized domain-adjacent copy

**Files:**
- Modify: `LifeTimer/Persistence/DefaultCategorySeeder.swift`
- Modify: `LifeTimer/Persistence/CategoryModel.swift`
- Modify: `LifeTimer/Persistence/AnniversaryRepository.swift`
- Modify: `LifeTimer/Integrations/ReminderScheduler.swift`
- Modify: `LifeTimer/Integrations/CalendarExportService.swift`
- Modify: `LifeTimer/Domain/AnniversaryDraft.swift`
- Modify: `LifeTimerTests/DefaultCategorySeederTests.swift`
- Modify: `LifeTimerTests/ReminderSchedulerTests.swift`
- Modify: `LifeTimerTests/CalendarExportServiceTests.swift`

**Interfaces:**
- Consumes: `AppLocalization.string(_:locale:)` and stable built-in category UUIDs.
- Produces: `CategoryModel.displayName(locale:)`, localized mapped `CategoryReference.name`, localized notification bodies, and localized calendar attribution/error text.

- [ ] **Step 1: Add failing tests for language-switch-safe categories and service copy**

Assert that the same built-in category UUID resolves to `Family` in English and `家庭` in Simplified Chinese, a two-day reminder body is English when passed `en_US`, and the exported event note ends in `Created with Taisetsu` for English.

- [ ] **Step 2: Run focused tests and verify RED**

Run: `bash scripts/ci-test.sh -only-testing:LifeTimerTests/DefaultCategorySeederTests -only-testing:LifeTimerTests/ReminderSchedulerTests -only-testing:LifeTimerTests/CalendarExportServiceTests`

Expected: tests fail because locale injection/display-name resolution is absent.

- [ ] **Step 3: Implement display-time category localization**

Keep the five stable UUIDs and persisted seed rows. Map those UUIDs to localization keys for Family, Love, Birthday, Health, and Work; custom categories continue returning their stored user-entered names. Use the resolved name in repository domain mapping and UI lists.

- [ ] **Step 4: Localize notifications, validation, errors, and calendar attribution**

Add locale parameters with `.current` defaults at service boundaries. Build notification relative copy using the shared formatter and build calendar notes with the localized `Created with Taisetsu` value.

- [ ] **Step 5: Run focused tests and verify GREEN**

Run the Task 2 focused test command again and require zero failures.

### Task 3: Rebrand and translate app and widget bundles

**Files:**
- Modify: `project.yml`
- Modify: `LifeTimer/Resources/Localizable.xcstrings`
- Create: `LifeTimer/Resources/InfoPlist.xcstrings`
- Create: `LifeTimerWidget/Resources/Localizable.xcstrings`
- Modify: `LifeTimer/App/LifeTimerApp.swift`
- Modify: `LifeTimer/App/AppRootView.swift`
- Modify: `LifeTimer/Features/**/*.swift`
- Modify: `LifeTimerWidget/LifeTimerWidget.swift`
- Modify: `LifeTimerWidget/LifeTimerWidgetView.swift`
- Modify: `LifeTimerUITests/LifeTimerUITests.swift`

**Interfaces:**
- Consumes: all formatter/category interfaces from Tasks 1 and 2.
- Produces: Taisetsu branding, English source copy, and complete translations for every catalog key in all required non-English locales.

- [ ] **Step 1: Write a failing English UI localization smoke test**

Launch with `-AppleLanguages (en)` and assert that the tab bar exposes `Home`, `Calendar`, and `Settings`, and that the home navigation title is `Taisetsu`. Update existing UI tests to launch with `-AppleLanguages (zh-Hans)` so their Chinese assertions are deterministic.

- [ ] **Step 2: Run the English UI smoke test and verify RED**

Run: `LIFETIMER_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh -only-testing:LifeTimerUITests/LifeTimerUITests/testLaunchesWithEnglishLocalization`

Expected: the English labels are absent before catalogs and source copy are updated.

- [ ] **Step 3: Apply public branding without changing technical identifiers**

Set both public display names to `Taisetsu`, change the home title to `Taisetsu`, set the application category to Lifestyle, and retain the existing development team settings from the dirty generated project by expressing them in `project.yml`.

- [ ] **Step 4: Replace raw static UI copy with English source copy and translate catalogs**

Cover app tabs, empty/error states, editor sections and controls, filters, detail view, category/tag management, settings, accessibility labels, widget configuration, widget empty/list states, and calendar permission usage text. Provide reviewed values for all eleven locale codes; Arabic text must render through SwiftUI's natural right-to-left direction.

- [ ] **Step 5: Run the English and Chinese UI smoke flows and verify GREEN**

Run the English test from Step 2, then run both existing editor smoke tests under their explicit Simplified Chinese launch language.

### Task 4: Automated localization completeness gate

**Files:**
- Create: `scripts/localization-check.sh`
- Modify: `scripts/verify.sh`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: the app and widget `.xcstrings` JSON schemas and the fixed required locale list.
- Produces: a zero exit code only when every translatable key contains a translated unit for each required non-source locale.

- [ ] **Step 1: Add the validator with a deliberately missing-locale fixture path**

The script accepts optional catalog paths so it can be exercised against a temporary incomplete catalog. It uses `jq` to reject absent localizations, `needs_review` states, empty values, and untranslated plural variations.

- [ ] **Step 2: Verify the validator fails against an incomplete catalog**

Run it against a temporary catalog containing only `en`; expect a non-zero exit and a message naming the missing locale.

- [ ] **Step 3: Run it against the production catalogs**

Run: `bash scripts/localization-check.sh`

Expected: exit 0 with both app and widget catalogs reported complete.

- [ ] **Step 4: Wire the gate into local and GitHub CI verification**

Call the script before formatting/build steps in `scripts/verify.sh` and add a named `Validate localizations` step after XcodeGen drift checking in `.github/workflows/ci.yml`.

### Task 5: Documentation, generated project, and release verification

**Files:**
- Modify: `README.md`
- Create: `docs/brand-localization.md`
- Regenerate: `LifeTimer.xcodeproj/project.pbxproj`
- Regenerate: `LifeTimer/Info.plist`
- Regenerate: `LifeTimerWidget/Info.plist`

**Interfaces:**
- Consumes: approved Taisetsu naming system and all implementation outputs.
- Produces: contributor-facing localization instructions and reproducible generated Xcode files.

- [ ] **Step 1: Document the public brand and technical-name compatibility boundary**

Update the README title and product description to Taisetsu. Document the eleven locales, invariant brand name, localized descriptor/tagline examples, and the rule that internal `LifeTimer` identifiers must not be renamed.

- [ ] **Step 2: Regenerate the Xcode project and check generated-file drift**

Run: `xcodegen generate`

Then run the same `git diff --exit-code` path set used by CI after staging/inspecting expected generated changes.

- [ ] **Step 3: Run complete verification**

Run: `bash scripts/verify.sh`

Expected: localization gate, formatter lint, build,  all unit tests, and coverage gate pass.

- [ ] **Step 4: Run UI smoke verification**

Run: `LIFETIMER_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh -only-testing:LifeTimerUITests/LifeTimerUITests/testCreatesAnAnniversaryFromTheEmptyState -only-testing:LifeTimerUITests/LifeTimerUITests/testEditorUsesDateWheelsAndStructuredRecurrenceControls -only-testing:LifeTimerUITests/LifeTimerUITests/testLaunchesWithEnglishLocalization`

Expected: all three UI flows pass.

- [ ] **Step 5: Review, commit, push, and verify remote state**

Inspect `git diff --check`, the full diff, and `git status`; commit intentionally to `main`, push `main`, then confirm local `HEAD` equals `origin/main` and the working tree is clean.

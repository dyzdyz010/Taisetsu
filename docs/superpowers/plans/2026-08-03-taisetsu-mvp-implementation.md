# Taisetsu MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a production-quality iOS/iPadOS Taisetsu MVP with Gregorian and Chinese-lunar anniversaries, recurrence, CRUD, categories and tags, local reminders, iCloud-ready persistence, Calendar export, three widget families, tests, and GitHub CI.

**Architecture:** A pure `TaisetsuCore` framework owns recurrence, occurrence, sorting, filtering, and widget snapshot value types. The app owns SwiftData models and repositories, then coordinates notification, EventKit, and App Group side effects only after successful persistence. The widget extension reads an atomic App Group JSON snapshot and never opens the app's SwiftData store.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Foundation Calendar, UserNotifications, EventKit, WidgetKit, AppIntents, XcodeGen, Swift Testing, XCTest UI tests, GitHub Actions.

## Global Constraints

- The product is local-first and requires no account or custom backend.
- The first release supports iPhone and iPad with a minimum deployment target of iOS 18.0.
- The primary language is Simplified Chinese; every user-facing string must use a localization key or `LocalizedStringResource`.
- The app supports light/dark appearance, Dynamic Type, VoiceOver, and Reduce Motion.
- No third-party runtime dependencies are allowed.
- SwiftData relationships must remain CloudKit-compatible: optional relationships, stable UUIDs, no unique-constraint dependency, and no deny delete rules.
- `OccurrenceCalculator` is the only source for original, previous, next, elapsed, and remaining date semantics.
- `isPinned` affects both Home and Widget ordering; `isVisibleInWidget` only affects widgets.
- Widgets support `.systemSmall`, `.systemMedium`, and `.systemLarge`, showing 1, 4, and 5 events respectively.
- Calendar export is one-way and user-triggered; each export updates one nonrecurring event representing the next occurrence.
- Tests are part of every feature task and must pass before its commit.

## Planned File Structure

```text
project.yml                                  Reproducible Xcode project definition
TaisetsuCore/
  Configuration/AppConfiguration.swift       Shared bundle and container identifiers
  Domain/AnniversaryDraft.swift              Editable domain input
  Domain/AnniversaryRecord.swift             Read-only domain representation
  Domain/CalendarKind.swift                  Gregorian/Chinese calendar choice
  Domain/DisplayMode.swift                   Count down/count up/both
  Domain/RecurrenceRule.swift                Anchored recurrence value
  Domain/ReminderSpec.swift                  Reminder value
  Domain/Occurrence.swift                    Calculated occurrence result
  Domain/OccurrenceCalculator.swift          All calendar arithmetic
  Domain/AnniversaryOrdering.swift           Pin/upcoming/count-up ordering
  Domain/AnniversaryFilter.swift             Search/category/tag filtering
  Widget/WidgetSnapshot.swift                Versioned App Group DTO
Taisetsu/
  App/TaisetsuApp.swift                     Composition root and ModelContainer
  App/AppDependencies.swift                  Service dependency graph
  App/AppRootView.swift                      Three-tab root
  Persistence/AnniversaryModel.swift         SwiftData anniversary
  Persistence/CategoryModel.swift            SwiftData category
  Persistence/TagModel.swift                 SwiftData tag
  Persistence/ReminderRuleModel.swift        SwiftData reminder
  Persistence/ModelContainerFactory.swift    Local/CloudKit container creation
  Persistence/AnniversaryRepository.swift    CRUD and mapping
  Persistence/DefaultCategorySeeder.swift    Idempotent defaults
  Coordination/ReconciliationCoordinator.swift Side-effect reconciliation
  Integrations/NotificationCenterClient.swift Testable notification adapter
  Integrations/ReminderScheduler.swift       Rolling notification schedule
  Integrations/EventStoreClient.swift        Testable EventKit adapter
  Integrations/CalendarExportService.swift   Create/update exported event
  Integrations/WidgetSnapshotStore.swift     Atomic App Group writer
  Features/Home/                             Home state and views
  Features/Editor/                           Create/edit form
  Features/Detail/                           Anniversary detail
  Features/Calendar/                         Month calendar
  Features/Settings/                         Category/tag/permission settings
  Shared/                                    Formatting, style, reusable views
TaisetsuWidget/
  TaisetsuWidgetBundle.swift                Widget bundle entry
  TaisetsuWidget.swift                      Configuration and provider
  TaisetsuWidgetEntry.swift                 Timeline entry
  TaisetsuWidgetView.swift                  Family-adaptive view
TaisetsuTests/                              Unit and service tests
TaisetsuUITests/                            Core user-flow UI tests
scripts/ci-test.sh                           Deterministic simulator test runner
scripts/verify.sh                            Project generation, format, build, tests
.github/workflows/ci.yml                     Build/test/coverage workflow
.github/workflows/codeql.yml                 Swift CodeQL workflow
.github/dependabot.yml                       GitHub Actions update policy
README.md                                    Public project documentation
LICENSE                                      MIT license
```

---

### Task 1: Reproducible Project Foundation

**Files:**
- Create: `project.yml`
- Create: `.swift-format`
- Create: `scripts/ci-test.sh`
- Create: `TaisetsuCore/Configuration/AppConfiguration.swift`
- Modify: `Taisetsu.xcodeproj/project.pbxproj`
- Move: `Taisetsu/TaisetsuApp.swift` to `Taisetsu/App/TaisetsuApp.swift`
- Delete: `Taisetsu/Item.swift`
- Delete: `Taisetsu/ContentView.swift`
- Test: `TaisetsuTests/ProjectFoundationTests.swift`

**Interfaces:**
- Consumes: the existing Xcode template and approved design.
- Produces: schemes `Taisetsu`, `TaisetsuCore`, and `TaisetsuWidget`; an app group `group.com.dyz.Taisetsu`; an iCloud container `iCloud.com.dyz.Taisetsu`; `scripts/ci-test.sh` used by all later tasks and CI.

- [ ] **Step 1: Commit the already staged Xcode template as an unchanged baseline**

```bash
git commit -m "chore: add initial Xcode project"
```

- [ ] **Step 2: Write a failing foundation test**

```swift
import Testing
@testable import TaisetsuCore

struct ProjectFoundationTests {
    @Test func appGroupIdentifierIsStable() {
        #expect(AppConfiguration.appGroupIdentifier == "group.com.dyz.Taisetsu")
    }
}
```

- [ ] **Step 3: Run the test and record the expected missing-type failure**

Run: `xcodebuild test -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:TaisetsuTests/ProjectFoundationTests`

Expected: FAIL because `AppConfiguration` does not exist.

- [ ] **Step 4: Add XcodeGen configuration and the app configuration type**

Define four targets in `project.yml`: `TaisetsuCore` framework, `Taisetsu` application, `TaisetsuWidget` app extension, and the two test targets. Set iOS 18.0, Swift 6, strict concurrency, shared schemes, code coverage, app/widget entitlements, and filesystem source paths. Add this complete configuration type:

```swift
public enum AppConfiguration {
    public static let appGroupIdentifier = "group.com.dyz.Taisetsu"
    public static let cloudContainerIdentifier = "iCloud.com.dyz.Taisetsu"
    public static let widgetKind = "TaisetsuUpcoming"
}
```

- [ ] **Step 5: Generate the project and add a dynamic simulator runner**

`scripts/ci-test.sh` must select the first available iPhone from the newest installed simulator runtime, then run:

```bash
xcodebuild test \
  -project Taisetsu.xcodeproj \
  -scheme Taisetsu \
  -destination "platform=iOS Simulator,id=${TAISETSU_SIMULATOR_UDID}" \
  -enableCodeCoverage YES \
  -resultBundlePath .build/TestResults.xcresult
```

- [ ] **Step 6: Verify generation, formatting, build, and the foundation test**

Run: `xcodegen generate && xcrun swift-format lint -r Taisetsu TaisetsuCore TaisetsuWidget TaisetsuTests && bash scripts/ci-test.sh`

Expected: project generation succeeds, format lint exits 0, and the foundation test passes.

- [ ] **Step 7: Commit**

```bash
git add project.yml .swift-format scripts Taisetsu TaisetsuCore TaisetsuWidget TaisetsuTests Taisetsu.xcodeproj
git commit -m "chore: establish reproducible Xcode project"
```

### Task 2: Date Domain and Occurrence Calculator

**Files:**
- Create: `TaisetsuCore/Domain/CalendarKind.swift`
- Create: `TaisetsuCore/Domain/DisplayMode.swift`
- Create: `TaisetsuCore/Domain/RecurrenceRule.swift`
- Create: `TaisetsuCore/Domain/ReminderSpec.swift`
- Create: `TaisetsuCore/Domain/AnniversaryRecord.swift`
- Create: `TaisetsuCore/Domain/Occurrence.swift`
- Create: `TaisetsuCore/Domain/OccurrenceCalculator.swift`
- Test: `TaisetsuTests/OccurrenceCalculatorTests.swift`

**Interfaces:**
- Consumes: Foundation `Calendar`, `DateComponents`, `TimeZone`.
- Produces: `OccurrenceCalculator.calculate(for:relativeTo:timeZone:) throws -> Occurrence`; all later sorting, UI, reminders, widgets, and export use this method.

- [ ] **Step 1: Write failing Gregorian boundary tests**

Cover one-time future/past events, all-day day boundaries, a February 29 yearly event falling back to February 28, January 31 monthly recurrence falling back to month-end, and every-N-month anchoring.

```swift
@Test func yearlyLeapDayFallsBackToFebruary28() throws {
    let record = AnniversaryRecord.fixture(
        year: 2024, month: 2, day: 29,
        recurrence: .init(unit: .year, interval: 1)
    )
    let result = try calculator.calculate(
        for: record,
        relativeTo: date("2025-02-01T12:00:00Z"),
        timeZone: utc
    )
    #expect(result.next == date("2025-02-28T00:00:00Z"))
}
```

- [ ] **Step 2: Run Gregorian tests and confirm missing-domain failures**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/OccurrenceCalculatorTests`

Expected: FAIL because the domain types and calculator do not exist.

- [ ] **Step 3: Implement immutable Sendable domain values and Gregorian calculation**

Use these public signatures:

```swift
public struct OccurrenceCalculator: Sendable {
    public init() {}
    public func calculate(
        for anniversary: AnniversaryRecord,
        relativeTo referenceDate: Date,
        timeZone: TimeZone
    ) throws -> Occurrence
}

public struct Occurrence: Equatable, Sendable {
    public let original: Date
    public let previous: Date?
    public let next: Date?
    public let elapsed: DateComponents?
    public let remaining: DateComponents?
    public let state: OccurrenceState
}
```

Compute every recurrence from the original anchor. Clamp invalid target days to the last valid day, and calculate all-day differences from calendar start-of-day values.

- [ ] **Step 4: Run Gregorian tests until green**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/OccurrenceCalculatorTests`

Expected: all Gregorian tests PASS.

- [ ] **Step 5: Write failing Chinese-calendar and DST tests**

Add fixtures that verify lunar month-day conversion, lunar day 30 fallback, leap-month fallback to the ordinary month when absent, exact-time events, and a nonexistent local time during DST transition moving to the first valid time.

- [ ] **Step 6: Implement Chinese-calendar and floating local-time behavior**

Use `Calendar(identifier: .chinese)`, preserve `DateComponents.isLeapMonth`, enumerate candidate Chinese-calendar years from the reference window, and validate every generated component through `Calendar.date(from:)`. Do not convert and persist a lunar event as a fixed Gregorian date.

- [ ] **Step 7: Run all occurrence tests and format lint**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/OccurrenceCalculatorTests && xcrun swift-format lint -r TaisetsuCore TaisetsuTests`

Expected: all date-domain tests PASS and lint exits 0.

- [ ] **Step 8: Commit**

```bash
git add TaisetsuCore/Domain TaisetsuTests/OccurrenceCalculatorTests.swift
git commit -m "feat: add anniversary occurrence engine"
```

### Task 3: Ordering, Filtering, and Widget Selection

**Files:**
- Create: `TaisetsuCore/Domain/AnniversaryOrdering.swift`
- Create: `TaisetsuCore/Domain/AnniversaryFilter.swift`
- Create: `TaisetsuCore/Widget/WidgetSnapshot.swift`
- Test: `TaisetsuTests/AnniversaryOrderingTests.swift`
- Test: `TaisetsuTests/AnniversaryFilterTests.swift`
- Test: `TaisetsuTests/WidgetSelectionTests.swift`

**Interfaces:**
- Consumes: `[AnniversaryRecord]` and occurrences from Task 2.
- Produces: `AnniversaryOrdering.sections(records:relativeTo:timeZone:)`, `AnniversaryFilter.matches`, and `WidgetSnapshot.make`.

- [ ] **Step 1: Write failing ordering and filtering tests**

Verify pinned upcoming, pinned count-up-only, normal upcoming, ongoing, and ended ordering. Verify normalized search across title, notes, category, and tags. Verify category AND all-selected-tags semantics.

- [ ] **Step 2: Run the tests and confirm missing-type failures**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/AnniversaryOrderingTests -only-testing:TaisetsuTests/AnniversaryFilterTests`

Expected: FAIL because ordering and filter types do not exist.

- [ ] **Step 3: Implement deterministic ordering and filtering**

```swift
public struct AnniversarySections: Equatable, Sendable {
    public let pinned: [AnniversaryPresentation]
    public let upcoming: [AnniversaryPresentation]
    public let ongoing: [AnniversaryPresentation]
    public let ended: [AnniversaryPresentation]
}

public struct AnniversaryFilter: Equatable, Sendable {
    public var query: String
    public var categoryID: UUID?
    public var requiredTagIDs: Set<UUID>
    public func matches(_ record: AnniversaryRecord) -> Bool
}
```

Normalize text with case/diacritic/width-insensitive folding and trim whitespace.

- [ ] **Step 4: Write failing widget capacity and visibility tests**

Verify hidden events are excluded, pinned visible events come first, and snapshot helpers return counts 1, 4, and 5 for small, medium, and large families.

- [ ] **Step 5: Implement versioned widget snapshot values**

```swift
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public let schemaVersion: Int
    public let generatedAt: Date
    public let timeZoneIdentifier: String
    public let localeIdentifier: String
    public let events: [WidgetEventSnapshot]
}
```

- [ ] **Step 6: Run all Task 3 tests and commit**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/AnniversaryOrderingTests -only-testing:TaisetsuTests/AnniversaryFilterTests -only-testing:TaisetsuTests/WidgetSelectionTests`

```bash
git add TaisetsuCore TaisetsuTests
git commit -m "feat: add anniversary ordering and widget snapshots"
```

### Task 4: SwiftData Models and Repository

**Files:**
- Create: `Taisetsu/Persistence/AnniversaryModel.swift`
- Create: `Taisetsu/Persistence/CategoryModel.swift`
- Create: `Taisetsu/Persistence/TagModel.swift`
- Create: `Taisetsu/Persistence/ReminderRuleModel.swift`
- Create: `Taisetsu/Persistence/ModelContainerFactory.swift`
- Create: `Taisetsu/Persistence/AnniversaryRepository.swift`
- Create: `Taisetsu/Persistence/DefaultCategorySeeder.swift`
- Create: `Taisetsu/Domain/AnniversaryDraft.swift`
- Test: `TaisetsuTests/AnniversaryRepositoryTests.swift`
- Test: `TaisetsuTests/DefaultCategorySeederTests.swift`

**Interfaces:**
- Consumes: core records and rules.
- Produces: `AnniversaryRepository.fetch(filter:)`, `save(draft:)`, `delete(id:)`, `setPinned(id:isPinned:)`, `setWidgetVisibility(id:isVisible:)`; in-memory and CloudKit-ready containers.

- [ ] **Step 1: Write failing CRUD, mapping, relationship, and validation tests**

Test empty-title rejection, recurrence interval rejection, create/update/delete, optional category, optional tag/reminder relationships, and round-trip mapping to `AnniversaryRecord`.

- [ ] **Step 2: Run repository tests and confirm model failures**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/AnniversaryRepositoryTests`

Expected: FAIL because persistence models and repository do not exist.

- [ ] **Step 3: Implement CloudKit-compatible models**

Every scalar has a default or is optional; every relationship is optional. Store domain enum raw values as strings. Use explicit inverses and cascade rules only where CloudKit supports them.

- [ ] **Step 4: Implement container factory with recoverable errors**

```swift
enum ModelContainerFactory {
    static func makePersistent(cloudSyncEnabled: Bool) throws -> ModelContainer
    static func makeInMemory() throws -> ModelContainer
}
```

The app path uses `.private(AppConfiguration.cloudContainerIdentifier)` when enabled and `.none` for previews/tests. Never use `fatalError` in production startup.

- [ ] **Step 5: Implement repository and idempotent default categories**

Seed 家庭, 爱情, 生日, 健康, and 工作 with stable UUIDs, SF Symbols, and semantic color tokens. Normalize names before saving and merge duplicate tags/categories deterministically.

- [ ] **Step 6: Run repository/seeder tests and commit**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/AnniversaryRepositoryTests -only-testing:TaisetsuTests/DefaultCategorySeederTests`

```bash
git add Taisetsu/Persistence Taisetsu/Domain TaisetsuTests
git commit -m "feat: add SwiftData anniversary repository"
```

### Task 5: Application Shell, Home, and Detail

**Files:**
- Create: `Taisetsu/App/AppDependencies.swift`
- Create: `Taisetsu/App/AppRootView.swift`
- Modify: `Taisetsu/App/TaisetsuApp.swift`
- Create: `Taisetsu/Features/Home/HomeView.swift`
- Create: `Taisetsu/Features/Home/HomeViewModel.swift`
- Create: `Taisetsu/Features/Home/AnniversaryHeroCard.swift`
- Create: `Taisetsu/Features/Home/AnniversaryRow.swift`
- Create: `Taisetsu/Features/Detail/AnniversaryDetailView.swift`
- Create: `Taisetsu/Shared/AnniversaryFormatters.swift`
- Create: `Taisetsu/Shared/CategoryStyle.swift`
- Test: `TaisetsuTests/HomeViewModelTests.swift`

**Interfaces:**
- Consumes: repository, calculator, ordering, filtering.
- Produces: a functioning Home tab and navigable detail screen; `AppDependencies` used by every feature.

- [ ] **Step 1: Write failing Home view-model tests**

Test empty/loading/error/content states, pin behavior, search/filter updates, and main-card selection for pinned and unpinned data.

- [ ] **Step 2: Run tests and confirm missing-view-model failure**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/HomeViewModelTests`

- [ ] **Step 3: Implement app composition and Home state**

Use `@MainActor @Observable final class HomeViewModel`. Repository calls happen outside the rendering body; calculated presentations are immutable. Inject a clock closure for deterministic tests.

- [ ] **Step 4: Implement the approved “原生克制” Home UI**

Use a hero card, sectioned list, searchable text, category/tag filter sheet, swipe pin/edit/delete actions, empty state, and navigation to detail. Category colors are accents only; every state also has text or a symbol.

- [ ] **Step 5: Implement detail display and formatting**

Show original date, Chinese calendar description, elapsed/remaining values, recurrence, reminders, category/tags, widget/pin state, edit/delete/export actions. Use system locale formatting and LocalizedStringResource.

- [ ] **Step 6: Run Home tests, build, and commit**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/HomeViewModelTests && xcodebuild build -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`

```bash
git add Taisetsu/App Taisetsu/Features/Home Taisetsu/Features/Detail Taisetsu/Shared TaisetsuTests
git commit -m "feat: build anniversary home and detail views"
```

### Task 6: Editor, Categories, and Tags

**Files:**
- Create: `Taisetsu/Features/Editor/AnniversaryEditorView.swift`
- Create: `Taisetsu/Features/Editor/AnniversaryEditorViewModel.swift`
- Create: `Taisetsu/Features/Editor/DateRuleSection.swift`
- Create: `Taisetsu/Features/Editor/RecurrenceSection.swift`
- Create: `Taisetsu/Features/Editor/ReminderSection.swift`
- Create: `Taisetsu/Features/Editor/CategoryTagSection.swift`
- Create: `Taisetsu/Features/Settings/CategoryManagerView.swift`
- Create: `Taisetsu/Features/Settings/TagManagerView.swift`
- Test: `TaisetsuTests/AnniversaryEditorViewModelTests.swift`
- Test: `TaisetsuTests/CategoryTagManagementTests.swift`

**Interfaces:**
- Consumes: `AnniversaryDraft`, repository, categories, tags.
- Produces: complete create/edit/delete UI and category/tag management.

- [ ] **Step 1: Write failing editor state and validation tests**

Cover create and edit initialization, Gregorian/Chinese switching, all-day/exact-time fields, recurrence interval, display mode, multiple reminders, category/tag selection, pin/visibility, draft preservation after save failure, and validation messages.

- [ ] **Step 2: Run tests and confirm missing-editor failure**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/AnniversaryEditorViewModelTests`

- [ ] **Step 3: Implement editor view model and sections**

Use a single observable draft. The save method validates synchronously, awaits repository save, and dismisses only after success. Disable “事件发生时” for all-day events and keep each reminder independently enabled.

- [ ] **Step 4: Add editor presentation from Home and Detail**

Present create/edit in a sheet with NavigationStack, cancel confirmation when dirty, and localized inline validation. After successful save, refresh Home and Detail through repository observation or explicit completion.

- [ ] **Step 5: Write and implement category/tag management tests**

Verify default categories, add/rename/hide/style category, add/delete tag, normalization, and duplicate merging. Destructive category deletion moves events to 未分类; tag deletion removes the optional relation.

- [ ] **Step 6: Run editor/category tests and commit**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/AnniversaryEditorViewModelTests -only-testing:TaisetsuTests/CategoryTagManagementTests`

```bash
git add Taisetsu/Features/Editor Taisetsu/Features/Settings TaisetsuTests
git commit -m "feat: add anniversary editor and organization"
```

### Task 7: Calendar and Settings Tabs

**Files:**
- Create: `Taisetsu/Features/Calendar/CalendarView.swift`
- Create: `Taisetsu/Features/Calendar/CalendarViewModel.swift`
- Create: `Taisetsu/Features/Calendar/MonthGrid.swift`
- Create: `Taisetsu/Features/Settings/SettingsView.swift`
- Create: `Taisetsu/Features/Settings/PermissionStatusView.swift`
- Modify: `Taisetsu/App/AppRootView.swift`
- Test: `TaisetsuTests/CalendarViewModelTests.swift`

**Interfaces:**
- Consumes: repository and `OccurrenceCalculator`.
- Produces: month grouping by calculated Gregorian occurrence and Settings navigation.

- [ ] **Step 1: Write failing month-layout and event-grouping tests**

Test first-weekday offsets, leap months, Gregorian and lunar events landing on the same day, month navigation, selected-day events, and locale-driven weekday order.

- [ ] **Step 2: Run tests and confirm missing-calendar failure**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/CalendarViewModelTests`

- [ ] **Step 3: Implement calendar model and accessible grid**

Use LazyVGrid with seven columns, system calendar weekday order, VoiceOver date summaries, category-colored dots plus event counts, and a selected-day list. Recompute lunar occurrences for the visible month.

- [ ] **Step 4: Implement Settings shell**

Add category/tag management, default reminder presets, iCloud state, notification/calendar permission state, privacy, and about sections. Permission rows only deep-link to Settings after denial.

- [ ] **Step 5: Run Calendar tests, full build, and commit**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/CalendarViewModelTests && xcodebuild build -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`

```bash
git add Taisetsu/Features/Calendar Taisetsu/Features/Settings Taisetsu/App TaisetsuTests
git commit -m "feat: add calendar and settings tabs"
```

### Task 8: Local Reminder Scheduling

**Files:**
- Create: `Taisetsu/Integrations/NotificationCenterClient.swift`
- Create: `Taisetsu/Integrations/ReminderScheduler.swift`
- Test: `TaisetsuTests/ReminderSchedulerTests.swift`

**Interfaces:**
- Consumes: records, reminder specs, calculator, `UNUserNotificationCenter` adapter.
- Produces: `requestAuthorizationIfNeeded()`, `reconcile(records:relativeTo:)`, and `removeAll(for:)`.

- [ ] **Step 1: Write failing permission, identifier, and schedule-diff tests**

Test no prompt before first enabled reminder, denied permission preserving rules, stable identifiers, removal of obsolete requests, exact event-time reminders, day-offset wall time, lunar/custom concrete dates, and a bounded earliest-first rolling window.

- [ ] **Step 2: Run tests and confirm scheduler failures**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/ReminderSchedulerTests`

- [ ] **Step 3: Implement protocol adapter and scheduler**

```swift
protocol NotificationCenterClient: Sendable {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func pendingRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePendingRequests(withIdentifiers identifiers: [String])
}
```

Create one-shot `UNCalendarNotificationTrigger` requests from concrete calculated dates. Sort desired requests, preserve unrelated requests, and atomically reconcile owned identifiers.

- [ ] **Step 4: Connect editor permission flow and reconciliation**

Ask permission only when saving the first enabled reminder. Show inactive status after denial without dropping the saved rule.

- [ ] **Step 5: Run scheduler/full tests and commit**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/ReminderSchedulerTests`

```bash
git add Taisetsu/Integrations Taisetsu/Features/Editor TaisetsuTests
git commit -m "feat: schedule local anniversary reminders"
```

### Task 9: EventKit Calendar Export

**Files:**
- Create: `Taisetsu/Integrations/EventStoreClient.swift`
- Create: `Taisetsu/Integrations/CalendarExportService.swift`
- Modify: `Taisetsu/Features/Detail/AnniversaryDetailView.swift`
- Modify: `Taisetsu/Info.plist`
- Test: `TaisetsuTests/CalendarExportServiceTests.swift`

**Interfaces:**
- Consumes: record, next occurrence, repository export identifier update.
- Produces: full-access authorization and create/update behavior for one nonrecurring EKEvent.

- [ ] **Step 1: Write failing authorization/create/update/missing tests**

Cover not-determined, denied, full-access, create on first export, update by identifier, recreate after system deletion with confirmation, and no repository mutation on EventKit failure.

- [ ] **Step 2: Run tests and confirm missing-service failure**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/CalendarExportServiceTests`

- [ ] **Step 3: Implement EventStore adapter and export service**

Export only `Occurrence.next` as a nonrecurring event. All-day events use exclusive end date on the following day; timed events use their exact start and a one-hour default duration. Store the event identifier only after EventKit save succeeds.

- [ ] **Step 4: Add localized permission text and Detail actions**

Add `NSCalendarsFullAccessUsageDescription`. Show export/update/recreate states, permission-denied guidance, progress, and nonblocking errors.

- [ ] **Step 5: Run export tests, build, and commit**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/CalendarExportServiceTests && xcodebuild build -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`

```bash
git add Taisetsu/Integrations Taisetsu/Features/Detail Taisetsu/Info.plist TaisetsuTests
git commit -m "feat: export anniversaries to Calendar"
```

### Task 10: App Group Snapshot and Widget Extension

**Files:**
- Create: `Taisetsu/Integrations/WidgetSnapshotStore.swift`
- Create: `TaisetsuWidget/TaisetsuWidgetBundle.swift`
- Create: `TaisetsuWidget/TaisetsuWidget.swift`
- Create: `TaisetsuWidget/TaisetsuWidgetEntry.swift`
- Create: `TaisetsuWidget/TaisetsuWidgetView.swift`
- Create: `TaisetsuWidget/TaisetsuWidget.entitlements`
- Modify: `project.yml`
- Modify: `Taisetsu.xcodeproj/project.pbxproj`
- Test: `TaisetsuTests/WidgetSnapshotStoreTests.swift`
- Test: `TaisetsuTests/WidgetTimelineTests.swift`

**Interfaces:**
- Consumes: WidgetSnapshot from Task 3 and App Group configuration.
- Produces: atomic snapshot persistence and `.systemSmall/.systemMedium/.systemLarge` timeline views.

- [ ] **Step 1: Write failing atomic-write and fallback tests**

Test temporary-file replacement, previous snapshot retention after failed write, schema mismatch, corrupt JSON, and missing App Group URL.

- [ ] **Step 2: Run tests and confirm missing-store failure**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/WidgetSnapshotStoreTests`

- [ ] **Step 3: Implement snapshot store and app-side reload**

Write `widget-snapshot.json` with `Data.write(options: .atomic)` in the App Group. After success, call `WidgetCenter.shared.reloadTimelines(ofKind: AppConfiguration.widgetKind)`.

- [ ] **Step 4: Write failing timeline boundary and family-capacity tests**

Verify timeline entries at local midnight, next occurrence, and display-unit boundaries; verify family capacities 1, 4, and 5; verify widget-gallery preview and stale-snapshot states.

- [ ] **Step 5: Implement WidgetKit provider and adaptive views**

Use AppIntentConfiguration without custom grouping. The widget reads the snapshot only, uses `containerBackground`, marks title/date as privacy-sensitive, supports Dynamic Type, and links each rendered event to `taisetsu://anniversary/<uuid>`.

- [ ] **Step 6: Generate project, run widget tests/build, and commit**

Run: `xcodegen generate && bash scripts/ci-test.sh -only-testing:TaisetsuTests/WidgetSnapshotStoreTests -only-testing:TaisetsuTests/WidgetTimelineTests && xcodebuild build -project Taisetsu.xcodeproj -scheme TaisetsuWidget -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`

```bash
git add Taisetsu/Integrations TaisetsuWidget project.yml Taisetsu.xcodeproj TaisetsuTests
git commit -m "feat: add Taisetsu home screen widgets"
```

### Task 11: Reconciliation, Sync States, and Recovery

**Files:**
- Create: `Taisetsu/Coordination/ReconciliationCoordinator.swift`
- Create: `Taisetsu/App/StartupState.swift`
- Create: `Taisetsu/Features/Settings/SyncStatusView.swift`
- Modify: `Taisetsu/App/TaisetsuApp.swift`
- Modify: `Taisetsu/App/AppDependencies.swift`
- Test: `TaisetsuTests/ReconciliationCoordinatorTests.swift`
- Test: `TaisetsuTests/StartupRecoveryTests.swift`

**Interfaces:**
- Consumes: repository, reminder scheduler, snapshot store, lifecycle/time-zone notifications.
- Produces: one idempotent `reconcile(reason:now:)` operation and recoverable app startup.

- [ ] **Step 1: Write failing reconciliation order/idempotency tests**

Verify repository fetch precedes side effects, reminder failure does not block snapshot, snapshot failure preserves data, duplicate tag/category reconciliation is deterministic, and repeated runs create no duplicate side effects.

- [ ] **Step 2: Run tests and confirm missing-coordinator failure**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/ReconciliationCoordinatorTests`

- [ ] **Step 3: Implement actor-isolated coordinator**

```swift
actor ReconciliationCoordinator {
    func reconcile(reason: ReconciliationReason, now: Date) async -> ReconciliationReport
}
```

Trigger after local save, app activation, observed model changes, significant time change, locale change, and time-zone change. Coalesce concurrent requests and expose a report without logging user content.

- [ ] **Step 4: Replace fatal startup with recoverable state**

The app displays loading, ready, or recoverable-error states. A retry rebuilds the container; a local-only fallback is available when CloudKit configuration fails while preserving the original store URL.

- [ ] **Step 5: Add simplified sync status UI and lifecycle hooks**

Show 已同步, 同步中, or 暂不可用 without blocking local edits. Reconcile on foreground and significant clock changes.

- [ ] **Step 6: Run reconciliation/startup tests and commit**

Run: `bash scripts/ci-test.sh -only-testing:TaisetsuTests/ReconciliationCoordinatorTests -only-testing:TaisetsuTests/StartupRecoveryTests`

```bash
git add Taisetsu/Coordination Taisetsu/App Taisetsu/Features/Settings TaisetsuTests
git commit -m "feat: reconcile synced anniversary side effects"
```

### Task 12: Accessibility, UI Flows, and Performance

**Files:**
- Modify: `Taisetsu/Features/**/*.swift`
- Modify: `TaisetsuWidget/*.swift`
- Replace: `TaisetsuUITests/TaisetsuUITests.swift`
- Replace: `TaisetsuUITests/TaisetsuUITestsLaunchTests.swift`
- Create: `TaisetsuTests/AccessibilityContractTests.swift`
- Create: `TaisetsuTests/PerformanceTests.swift`
- Create: `Taisetsu/Resources/Localizable.xcstrings`

**Interfaces:**
- Consumes: all user-facing features.
- Produces: deterministic launch arguments and complete accessibility/localization contracts.

- [ ] **Step 1: Add failing localization and accessibility contract tests**

Require Simplified Chinese keys for tabs, editor fields, errors, permissions, empty states, and widget copy. Require stable accessibility identifiers for add, save, search, filter, pin, delete, export, tab, and editor controls.

- [ ] **Step 2: Implement string catalog and accessibility metadata**

Use semantic labels/values/hints, minimum hit targets, non-color status, Dynamic Type layouts, scrollable forms, privacy-sensitive widget content, and Reduce Motion checks.

- [ ] **Step 3: Write UI tests for core flows**

Use `-ui-testing`, `-reset-store`, and `-seed-sample-data` launch arguments. Test create/edit/delete, search/filter, pin/unpin, calendar navigation, permission-denied banners, and detail navigation.

- [ ] **Step 4: Add 1,000-record performance tests**

Measure occurrence calculation, ordering/filtering, and snapshot generation off the main actor. Assert the generated result counts and use XCTest measure baselines rather than device-specific hardcoded milliseconds.

- [ ] **Step 5: Run unit/UI tests in light and dark modes**

Run: `bash scripts/ci-test.sh && TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh`

Expected: all unit and UI tests PASS.

- [ ] **Step 6: Commit**

```bash
git add Taisetsu TaisetsuWidget TaisetsuTests TaisetsuUITests
git commit -m "test: cover Taisetsu user journeys"
```

### Task 13: CI, Security, and Public Documentation

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/codeql.yml`
- Create: `.github/dependabot.yml`
- Create: `.github/pull_request_template.md`
- Create: `scripts/verify.sh`
- Create: `README.md`
- Create: `LICENSE`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: generated project and full test suite.
- Produces: reproducible public CI and contributor-facing documentation.

- [ ] **Step 1: Add a local verification script**

`scripts/verify.sh` must run, in order:

```bash
xcodegen generate
git diff --exit-code -- Taisetsu.xcodeproj/project.pbxproj
xcrun swift-format lint -r Taisetsu TaisetsuCore TaisetsuWidget TaisetsuTests TaisetsuUITests
xcodebuild build -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
bash scripts/ci-test.sh
git diff --check
```

- [ ] **Step 2: Create least-privilege Build and Test CI**

Use `macos-26`, `permissions: contents: read`, concurrency cancellation per branch, a 30-minute timeout, a pinned Xcode 26 installation, XcodeGen project drift checking, Swift format lint, unsigned simulator build, full unit tests with coverage, coverage summary in the GitHub step summary, and `.xcresult` artifact upload on failure.

- [ ] **Step 3: Add Swift CodeQL and dependency maintenance**

Use `github/codeql-action` with Swift and a manual unsigned Xcode build. Add weekly Dependabot updates for GitHub Actions, grouped into one maintenance pull request.

- [ ] **Step 4: Write public README and license**

README must include features, architecture diagram, requirements, XcodeGen setup, build/test commands, CloudKit/App Group configuration, privacy behavior, CI badges, roadmap exclusions, and contribution guidance. Use the MIT license with year 2026 and copyright holder `dyz`.

- [ ] **Step 5: Run local verification and commit**

Run: `bash scripts/verify.sh`

Expected: generation clean, lint clean, build succeeds, tests pass, and diff check exits 0.

```bash
git add .github scripts README.md LICENSE .gitignore
git commit -m "ci: add build test and security automation"
```

### Task 14: Final Verification and GitHub Publication

**Files:**
- Modify only files required by final verification findings.

**Interfaces:**
- Consumes: the completed repository.
- Produces: a public GitHub repository with green CI and protected `main`.

- [ ] **Step 1: Run the full verification gate from a clean state**

Run: `bash scripts/verify.sh && git status --short && git log --oneline --decorate -15`

Expected: verification exits 0; only intentionally ignored local files remain; commit history is task-scoped.

- [ ] **Step 2: Perform a requirements audit against the design spec**

Check every acceptance item in `docs/superpowers/specs/2026-08-03-taisetsu-design.md` against a concrete test, build artifact, or documented manual prerequisite. Fix any code-verifiable gap and repeat Step 1.

- [ ] **Step 3: Create the public GitHub repository**

Authenticate with `gh`, choose the available public name `Taisetsu` or the deterministic fallback `Taisetsu-iOS`, create without adding remote-generated files, add `origin`, and push the completed `main` branch.

```bash
gh repo create Taisetsu --public --source=. --remote=origin --push --description "A local-first iOS anniversary countdown app with lunar dates, reminders, iCloud sync, and widgets."
```

- [ ] **Step 4: Watch CI to completion and fix failures**

Run: `gh run list --limit 10` and `gh run watch <run-id> --exit-status` for Build and Test plus CodeQL. For any failure, inspect logs, reproduce locally, add or adjust a regression test, commit the fix, push, and watch the new run.

- [ ] **Step 5: Configure repository protections and metadata**

Set topics `ios`, `swiftui`, `swiftdata`, `widgetkit`, `cloudkit`, `anniversary`, `countdown`; enable issues; configure `main` to prevent force pushes/deletion and require the stable Build and Test status check for future changes. Do not require a status name until its first successful run exists.

- [ ] **Step 6: Record final evidence**

Capture repository URL, final commit, CI run URLs/statuses, local verification output, and any manual Apple Developer prerequisites that cannot be completed without the repository owner's signing team.

---

## Execution Choice

The user explicitly requested uninterrupted execution without non-directional questions. Execute this plan inline in the current session using `superpowers:executing-plans`, with internal checkpoints after each task and no user pause unless a genuine product-direction or credential blocker occurs.

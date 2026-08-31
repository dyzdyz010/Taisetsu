# Interaction Performance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove main-thread latency from navigation and calendar month transitions while simplifying refresh and render-time data ownership.

**Architecture:** Build immutable calendar and reconciliation projections from sendable domain records, cache the expensive lunar year index, and let SwiftUI render cached state only. Keep SwiftData and system APIs at their existing boundaries, but coalesce refresh requests and batch calendar-sync persistence.

**Tech Stack:** Swift 6, SwiftUI, Observation, SwiftData, Swift Testing, XCTest UI performance metrics, WidgetKit, UserNotifications, EventKit

**Spec:** `docs/superpowers/specs/2026-08-31-interaction-performance-design.md`

## Completion Evidence

- Completed on 2026-08-31 with each implementation slice committed independently.
- `bash scripts/verify.sh`: 70 tests across 21 suites passed; TaisetsuCore line coverage was 93.12%.
- `TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/verify.sh`: the full UI target passed 72/72 tests, including 64 launch configurations and 8 interaction tests; the configured release smoke rerun passed 4/4 tests. The UI run reported 94.20% TaisetsuCore line coverage.
- Two isolated calendar-navigation measurements averaged 3.629 and 3.562 seconds for ten alternating month taps (approximately 0.363 and 0.356 seconds per XCUI tap, including automation overhead).
- The production lunar cache is verified through an injected `ChineseCalendarYearCache` test seam; no production-only cache reset or inspection API was added.

## Global Constraints

- iOS and iPadOS deployment target remains 18.0.
- Swift strict concurrency remains `complete`.
- `OccurrenceCalculator` remains the only recurrence-rule implementation.
- SwiftData models retain CloudKit-compatible defaults, optional relationships, and no unique constraints.
- No repository access, occurrence loop, yearly lunar scan, or synchronous file write may run from a SwiftUI render path.
- Do not add timers, retry layers, debounce latency, dependencies, or alternate fallback algorithms.
- After creating or moving a source file, run `xcodegen generate` before building; `project.yml` remains the project structure SSOT and the generated `Taisetsu.xcodeproj/project.pbxproj` is committed with that task.

---

### Task 1: Cache the Chinese calendar year index

**Files:**
- Create: `TaisetsuCore/Domain/ChineseCalendarDateResolver.swift`
- Modify: `TaisetsuCore/Domain/OccurrenceCalculator.swift`
- Modify: `TaisetsuTests/OccurrenceCalculatorTests.swift`

**Interfaces:**
- Produces: existing `ChineseCalendarDateResolver.date(...)` and `monthLength(...)` APIs backed by a synchronized 32-entry year/time-zone cache.
- Produces for tests: internal `ChineseCalendarDateResolver.resetCache()` and `cachedYearCount`.

- [x] **Step 1: Write the failing cache-reuse test**

```swift
@Test func chineseResolverBuildsOneIndexForSeveralMonthsInTheSameYear() throws {
    ChineseCalendarDateResolver.resetCache()
    let timeZone = try #require(TimeZone(identifier: "Asia/Shanghai"))
    _ = ChineseCalendarDateResolver.date(
        gregorianAnchorYear: 2026, lunarMonth: 1, day: 1,
        prefersLeapMonth: false, timeZone: timeZone
    )
    _ = ChineseCalendarDateResolver.monthLength(
        gregorianAnchorYear: 2026, lunarMonth: 8,
        prefersLeapMonth: false, timeZone: timeZone
    )
    #expect(ChineseCalendarDateResolver.cachedYearCount == 1)
}
```

- [x] **Step 2: Run the focused test and verify RED**

Run: `xcodebuild test -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'platform=iOS Simulator,id=0E3FFC71-F7F6-4B45-BBA6-032877D653F1' -parallel-testing-enabled NO -only-testing:TaisetsuTests/OccurrenceCalculatorTests`

Expected: compilation fails because `resetCache` and `cachedYearCount` do not exist.

- [x] **Step 3: Extract and index lunar year data**

Move the resolver out of `OccurrenceCalculator.swift`. Add `YearKey`, `MonthKey`, `YearIndex`, and a `Synchronization.Mutex<CacheState>`. Build one `[MonthKey: [Date]]` map in a single year scan, update LRU order on access, and evict the oldest key when inserting entry 33. Keep date clamping and leap-month selection identical.

Run: `xcodegen generate`

- [x] **Step 4: Run lunar and occurrence tests and verify GREEN**

Run the focused command from Step 2. Expected: all `OccurrenceCalculatorTests` pass.

- [x] **Step 5: Commit**

```bash
git add TaisetsuCore/Domain/ChineseCalendarDateResolver.swift TaisetsuCore/Domain/OccurrenceCalculator.swift TaisetsuTests/OccurrenceCalculatorTests.swift Taisetsu.xcodeproj/project.pbxproj
git commit -m "perf: cache Chinese calendar year indexes"
```

### Task 2: Build one immutable calendar projection per month

**Files:**
- Create: `TaisetsuCore/Calendar/CalendarMonthSnapshot.swift`
- Create: `TaisetsuTests/CalendarMonthSnapshotTests.swift`

**Interfaces:**
- Produces: `CalendarDayKey: Hashable, Sendable`.
- Produces: `CalendarMonthSnapshot: Equatable, Sendable` with `month`, `cells`, `events`, `eventDays`, and `hasEvent(on:calendar:)`.
- Produces: `CalendarMonthBuilder.make(records:month:calendar:timeZone:) throws -> CalendarMonthSnapshot`.
- Test seam: internal `CalendarMonthBuilder.init(calculate:)` accepting a `@Sendable` occurrence closure.

- [x] **Step 1: Write the failing single-pass projection test**

```swift
@Test func monthBuilderCalculatesEachRecordOnceAndIndexesEventDays() throws {
    let calls = Mutex(0)
    let builder = CalendarMonthBuilder { record, reference, _ in
        calls.withLock { $0 += 1 }
        let eventDate = utcCalendar.date(
            from: DateComponents(year: 2026, month: 8, day: record.date.day)
        )!
        return Occurrence(
            original: eventDate,
            previous: nil,
            next: eventDate,
            elapsed: nil,
            remaining: nil,
            state: .upcoming
        )
    }
    let records = [record(day: 5), record(day: 12), record(day: 27)]
    let snapshot = try builder.make(
        records: records, month: date("2026-08-01T00:00:00Z"),
        calendar: utcCalendar, timeZone: utc
    )
    #expect(calls.withLock { $0 } == records.count)
    #expect(snapshot.events.count == 3)
    #expect(snapshot.hasEvent(on: date("2026-08-12T00:00:00Z"), calendar: utcCalendar))
}
```

- [x] **Step 2: Run and verify RED**

Run the focused `xcodebuild test` command with `-only-testing:TaisetsuTests/CalendarMonthSnapshotTests`.

Expected: compilation fails because the calendar projection types do not exist.

- [x] **Step 3: Implement the projection**

Generate cells once from the injected calendar. Iterate records once, call the injected calculator once per record, keep only next occurrences inside the month interval, sort by next date, and derive `eventDays` once. Call `Task.checkCancellation()` inside the record loop.

Run: `xcodegen generate`

- [x] **Step 4: Run and verify GREEN**

Run the focused command from Step 2. Expected: the new suite passes.

- [x] **Step 5: Commit**

```bash
git add TaisetsuCore/Calendar/CalendarMonthSnapshot.swift TaisetsuTests/CalendarMonthSnapshotTests.swift Taisetsu.xcodeproj/project.pbxproj
git commit -m "perf: project calendar months in one pass"
```

### Task 3: Make CalendarView render cached state only

**Files:**
- Create: `Taisetsu/Features/Calendar/CalendarViewModel.swift`
- Modify: `Taisetsu/Features/Calendar/CalendarView.swift`
- Create: `TaisetsuTests/CalendarViewModelTests.swift`

**Interfaces:**
- Produces: `@MainActor @Observable CalendarViewModel` with `displayedMonth`, `snapshot`, `moveMonth(_:calendar:)`, and `refresh(calendar:timeZone:) async`.
- Consumes: `AnniversaryRepository.fetch()` once and `CalendarMonthBuilder` away from the main actor.

- [x] **Step 1: Write failing view-model tests**

Test that `moveMonth(1, calendar:)` changes `displayedMonth` immediately and that a build result tagged for an older month is discarded after a second move. Use an injected async build closure controlled by continuations so completion order is deterministic.

- [x] **Step 2: Run and verify RED**

Run the focused command with `-only-testing:TaisetsuTests/CalendarViewModelTests`.

Expected: compilation fails because `CalendarViewModel` does not exist.

- [x] **Step 3: Implement the view model and simplify the view**

Fetch records for each explicit month refresh so newly saved data remains visible. Capture the requested month before invoking the async builder and publish only when it still equals `displayedMonth`. Replace `eventsInMonth` and `monthCells` computed properties in the view with `viewModel.snapshot`. Use `.task(id: viewModel.displayedMonth)` for cancellation. Add `calendar-previous-month`, `calendar-next-month`, and `calendar-month-title` accessibility identifiers.

Run: `xcodegen generate`

- [x] **Step 4: Run focused tests and build**

Run the test from Step 2, then:

`xcodebuild build -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`

Expected: tests pass and build exits 0.

- [x] **Step 5: Commit**

```bash
git add Taisetsu/Features/Calendar TaisetsuTests/CalendarViewModelTests.swift Taisetsu.xcodeproj/project.pbxproj
git commit -m "perf: render cached calendar month state"
```

### Task 4: Move refresh planning off the main actor and coalesce requests

**Files:**
- Create: `Taisetsu/Coordination/ReconciliationPlan.swift`
- Modify: `Taisetsu/Coordination/ReconciliationCoordinator.swift`
- Modify: `Taisetsu/Integrations/ReminderScheduler.swift`
- Modify: `Taisetsu/App/AppRootView.swift`
- Create: `TaisetsuTests/ReconciliationCoordinatorTests.swift`

**Interfaces:**
- Produces: `ReconciliationPlan.make(records:referenceDate:timeZone:locale:reminderScheduler:) throws` returning a widget snapshot and reminder array.
- Produces: `ReminderScheduler.apply(_:client:) async throws` for already-calculated requests.
- Preserves: `ReconciliationCoordinator.reconcile() async` while guaranteeing one active pipeline and at most one coalesced follow-up.

- [x] **Step 1: Write the failing coalescing test**

Use an in-memory repository and a `@MainActor` notification client spy whose first `replaceTaisetsuRequests` call suspends. Start one reconcile, issue two more while suspended, release the first call, and assert `maximumConcurrentCalls == 1` and `callCount == 2`.

- [x] **Step 2: Run and verify RED**

Run the focused command with `-only-testing:TaisetsuTests/ReconciliationCoordinatorTests`.

Expected: current coordinator overlaps or executes three refreshes, so the assertions fail.

- [x] **Step 3: Split planning from application**

Calculate the widget snapshot and reminder schedule in `Task.detached(priority: .utility)`. Write the snapshot from that detached operation. Return to the main actor only to reload WidgetKit, apply notification requests, run EventKit synchronization, and publish error/summary state.

Run: `xcodegen generate`

- [x] **Step 4: Add request coalescing and one activation trigger**

Track `isReconciling` and `needsReconciliation`. Each caller sets the latter; only the owner loops until no follow-up is pending. Replace the root `.task` plus `.onChange` pair with one `.task(id: scenePhase)` guarded by `.active`.

- [x] **Step 5: Run and verify GREEN**

Run the focused test from Step 2 and `ReminderSchedulerTests`. Expected: all pass.

- [x] **Step 6: Commit**

```bash
git add Taisetsu/Coordination Taisetsu/Integrations/ReminderScheduler.swift Taisetsu/App/AppRootView.swift TaisetsuTests/ReconciliationCoordinatorTests.swift Taisetsu.xcodeproj/project.pbxproj
git commit -m "perf: coalesce background reconciliation"
```

### Task 5: Remove repository queries from render paths

**Files:**
- Modify: `Taisetsu/Features/Home/HomeViewModel.swift`
- Modify: `Taisetsu/Features/Home/HomeView.swift`
- Modify: `Taisetsu/Features/Editor/AnniversaryEditorViewModel.swift`
- Modify: `Taisetsu/Features/Settings/SettingsView.swift`
- Modify: `TaisetsuTests/HomeViewModelTests.swift`
- Modify: `TaisetsuTests/AnniversaryEditorViewModelTests.swift`

**Interfaces:**
- Produces: `HomeViewModel.categories` and `HomeViewModel.tags`, refreshed by `load()`.
- Produces: editor `categories` and `tags` stored once at initialization rather than computed repository reads.
- Produces: calendar-sync view state `managedEventsCount`, refreshed only on appearance or after a completed sync action.

- [x] **Step 1: Write failing cached-reference-data tests**

Extend the home and editor suites to insert a category and tag, then assert those values are exposed by the view model after `load()` or initialization. The new stored properties do not exist yet, so compilation must fail.

- [x] **Step 2: Run and verify RED**

Run the focused command with both affected test suites. Expected: compilation fails on the missing properties.

- [x] **Step 3: Cache reference and settings data**

Populate home reference arrays in `load()`, load editor arrays from its presentation `.task`, and make `FilterView` iterate the home arrays. Replace `calendarEntriesCount()` in `body` with state updated by a single `reload()` function called from `.task` and after sync completion.

- [x] **Step 4: Run and verify GREEN**

Run both focused suites, then use `rg` to confirm no `repository.` or `calendarEntriesCount()` call remains in a `body`-evaluated computed property in the modified views.

- [x] **Step 5: Commit**

```bash
git add Taisetsu/Features/Home Taisetsu/Features/Editor/AnniversaryEditorViewModel.swift Taisetsu/Features/Settings/SettingsView.swift TaisetsuTests/HomeViewModelTests.swift TaisetsuTests/AnniversaryEditorViewModelTests.swift
git commit -m "refactor: cache feature reference data"
```

### Task 6: Plan calendar sync off-main and persist entries once

**Files:**
- Create: `Taisetsu/Integrations/CalendarSyncPlan.swift`
- Modify: `Taisetsu/Integrations/CalendarAutoSyncService.swift`
- Modify: `Taisetsu/Persistence/CalendarSyncRepository.swift`
- Modify: `TaisetsuTests/CalendarAutoSyncServiceTests.swift`
- Modify: `TaisetsuTests/CalendarSyncRepositoryTests.swift`

**Interfaces:**
- Produces: sendable `CalendarSyncPlan` and `CalendarSyncPlanBuilder.make(records:settings:now:timeZone:) throws`.
- Produces: `CalendarSyncRepository.replaceEntries(with:) throws`, which fetches models once and calls `context.save()` once.
- Consumes: one existing-entry snapshot per calendar reconciliation.

- [x] **Step 1: Write failing replacement and planning tests**

Add a repository test that replaces two entries with one updated and one new entry, then replaces them with one entry and asserts the omitted model was deleted. Add a planner test that confirms the existing 128-per-record and 1,000-total caps without accessing EventKit.

- [x] **Step 2: Run and verify RED**

Run the two focused suites. Expected: compilation fails because `replaceEntries` and `CalendarSyncPlanBuilder` do not exist.

- [x] **Step 3: Implement the pure plan and batch repository API**

Move scope filtering, occurrence generation, ordering, and the 1,000 cap into the sendable plan builder. Implement `replaceEntries` using one model fetch, an ID-keyed dictionary, in-place updates/inserts, stale-model deletion, and one final save.

Run: `xcodegen generate`

- [x] **Step 4: Apply one plan and one persistence replacement**

Build the plan in `Task.detached(priority: .utility)`. Fetch existing entries once, update an in-memory result dictionary while applying EventKit operations, remove stale entries from that dictionary, and call `replaceEntries` once at the end. Preserve current partial-error summary behavior.

- [x] **Step 5: Run and verify GREEN**

Run `CalendarAutoSyncServiceTests` and `CalendarSyncRepositoryTests`. Expected: all pass with the existing idempotence, deletion, and cap behavior preserved.

- [x] **Step 6: Commit**

```bash
git add Taisetsu/Integrations/CalendarSyncPlan.swift Taisetsu/Integrations/CalendarAutoSyncService.swift Taisetsu/Persistence/CalendarSyncRepository.swift TaisetsuTests/CalendarAutoSyncServiceTests.swift TaisetsuTests/CalendarSyncRepositoryTests.swift Taisetsu.xcodeproj/project.pbxproj
git commit -m "perf: batch automatic calendar synchronization"
```

### Task 7: Add interaction evidence and run the full quality gate

**Files:**
- Modify: `TaisetsuUITests/TaisetsuUITests.swift`
- Modify: `docs/superpowers/plans/2026-08-31-interaction-performance.md`

**Interfaces:**
- Produces: `testCalendarNavigationPerformance` using the two month-button accessibility identifiers and `XCTClockMetric`.

- [x] **Step 1: Add the UI performance test**

Launch in English, select the Calendar tab, wait for `calendar-next-month`, and measure ten alternating next/previous taps with `XCTClockMetric`. Assert both controls still exist after measurement.

- [x] **Step 2: Run the interaction test**

Run:

`xcodebuild test -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'platform=iOS Simulator,id=0E3FFC71-F7F6-4B45-BBA6-032877D653F1' -parallel-testing-enabled NO -only-testing:TaisetsuUITests/TaisetsuUITests/testCalendarNavigationPerformance CODE_SIGNING_ALLOWED=NO`

Expected: test passes and the result bundle contains the clock metric.

- [x] **Step 3: Run project verification**

Run: `bash scripts/verify.sh`

Expected: naming, localization, XcodeGen drift, format lint, simulator build, unit tests, and coverage all pass.

- [x] **Step 4: Run UI smoke verification**

Run: `TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/verify.sh`

Expected: all configured UI smoke tests pass.

- [x] **Step 5: Inspect structure and diff**

Run `git diff --check`, `git status --short`, and `rg -n 'eventsInMonth|repository\.(fetch|categories|tags)\(\)|calendarEntriesCount\(\)' Taisetsu/Features`. Confirm the old calendar computed property is gone and any remaining repository calls occur only in explicit load/action functions.

- [x] **Step 6: Commit**

```bash
git add TaisetsuUITests/TaisetsuUITests.swift docs/superpowers/plans/2026-08-31-interaction-performance.md
git commit -m "test: cover calendar interaction performance"
```

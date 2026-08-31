# Interaction Performance and Structure Design

## Goal

Make every navigation action acknowledge immediately and make calendar month changes independent of record count on the main actor. Preserve existing product behavior while removing repeated work, duplicated refresh triggers, database reads during view rendering, and silent fallback paths that hide persistence failures.

## Evidence and root causes

1. `CalendarView.eventsInMonth` is a computed property used by the month list and by every populated day cell. One month transition recalculates every record roughly thirty times before accounting for additional SwiftUI body evaluations.
2. A Chinese-calendar date lookup scans every Gregorian day in the anchor year. The calendar view multiplies that scan by record count and day-cell count.
3. `ReconciliationCoordinator` is `@MainActor` and performs snapshot calculation, JSON encoding and writing, reminder schedule calculation, and automatic calendar planning before or between suspension points.
4. `AppRootView` starts reconciliation from both `.task` and the initial active `scenePhase`, producing duplicate startup work. Other callers can also overlap full refreshes.
5. Editor, filter, and calendar-sync views call repositories from computed properties or `body`, so unrelated observation changes can repeat SwiftData fetches during a transition.
6. Calendar synchronization fetches all sync entries repeatedly and saves the SwiftData context once per event.

The empty-data simulator remains responsive, which is consistent with these record-count-dependent paths.

## Considered approaches

### A. Local calendar memoization only

Cache `eventsInMonth` in `CalendarView`. This is small and fixes the clearest symptom, but leaves main-actor reconciliation, repeated repository reads, duplicate activation work, and the yearly lunar scan intact.

### B. Focused projection and refresh architecture — selected

Introduce pure, immutable projections for calendar and background refresh work. Views consume cached state, the coordinator coalesces requests, and pure calculation plus file I/O runs away from the main actor. Add a year-level Chinese-calendar index and batch calendar-sync persistence. This addresses all observed latency multipliers without replacing SwiftData or the system integrations.

### C. Full actor-based persistence rewrite

Move SwiftData and EventKit behind dedicated actors and convert every feature to async streams. This could improve very large data sets, but it expands migration and concurrency risk without evidence that the remaining single-fetch costs justify it.

## Architecture

### Calendar projection

`CalendarMonthSnapshot` in `TaisetsuCore` is the single source of truth for one rendered month. It contains:

- ordered calendar cells;
- the month's ordered presentations;
- a set of normalized event-day keys for constant-time dot lookup.

`CalendarMonthBuilder` calculates each record at most once per month. It receives the calendar, time zone, records, and month and produces the immutable snapshot.

`CalendarViewModel` owns `displayedMonth`, the loaded records, and the current snapshot. It changes the header state synchronously, builds the snapshot in a cancellable utility-priority task, and publishes only the result matching the current month. `CalendarView.body` performs no occurrence calculation or repository access.

### Chinese calendar index

`ChineseCalendarDateResolver` builds one immutable index for each Gregorian anchor year and time-zone identifier. The index scans the year once and groups dates by logical lunar month and leap-month flag. All date and month-length lookups reuse that index. A synchronized least-recently-used cache retains at most 32 year/time-zone indexes.

### Reconciliation pipeline

`ReconciliationPlan` contains the widget snapshot and reminder schedule. It is derived from the repository's sendable domain records in a detached utility-priority task. Widget JSON writing occurs with that background work; applying notification requests and reloading WidgetKit remain at their required system boundary.

`ReconciliationCoordinator.reconcile()` becomes a coalescing state machine: one run may be active and any number of overlapping requests collapse into at most one subsequent run. `AppRootView` has one activation trigger using `.task(id: scenePhase)`.

Automatic calendar occurrence planning also runs outside the main actor. Its persistence repository loads existing entries once, applies all upserts/deletes in memory, and saves the context once per reconciliation rather than once per event.

### Render-time data ownership

Feature view models load reference data once and expose immutable arrays to views:

- `HomeViewModel` owns filter categories and tags;
- `AnniversaryEditorViewModel` owns editor categories and tags;
- calendar-sync settings cache their managed-entry count.

No SwiftUI `body` or computed property used by `body` may call a repository.

## Data and error flow

SwiftData remains the authoritative store. Domain records cross into pure calculation as `Sendable` values. Calculation errors are returned to the owning view model or coordinator; the UI retains its last valid snapshot rather than rebuilding through a second fallback algorithm. Persistence APIs continue to report failures instead of inventing empty data for a failed operation where the calling screen already supports an error state.

System APIs stay behind their current clients. There is no new retry layer, timer, debounce delay, or speculative prefetch gate.

## File organization

- `TaisetsuCore/Calendar/CalendarMonthSnapshot.swift`: month projection types and builder.
- `TaisetsuCore/Domain/ChineseCalendarDateResolver.swift`: extracted indexed lunar lookup.
- `Taisetsu/Features/Calendar/CalendarViewModel.swift`: calendar interaction state.
- `Taisetsu/Features/Calendar/CalendarView.swift`: rendering only.
- `Taisetsu/Coordination/ReconciliationPlan.swift`: pure refresh preparation.
- `Taisetsu/Coordination/ReconciliationCoordinator.swift`: request coalescing and system orchestration.
- existing repository and feature view-model files: targeted query and cached reference-data changes.

`OccurrenceCalculator` remains the sole recurrence-rule implementation. The new calendar builder and background services call it rather than duplicating date rules.

## Testing and performance acceptance

1. A calendar builder test proves one calculator invocation per input record and constant-time day membership from the resulting snapshot.
2. Calendar view-model tests prove rapid month changes cannot publish a stale month.
3. Chinese-calendar tests prove indexed ordinary and leap-month resolution matches existing behavior across time zones.
4. Coordinator tests prove duplicate concurrent requests do not overlap and collapse into one follow-up run.
5. Calendar-sync repository tests prove a batch produces the same final entries with one save boundary.
6. Existing unit, UI, localization, naming, format, build, and coverage checks remain green.
7. Add an interaction UI performance test for calendar tab selection and repeated previous/next transitions, preserving its result bundle as comparison evidence.

The structural acceptance rule is strict: no repository call, yearly lunar scan, full-record occurrence loop, or synchronous file write may execute from a SwiftUI render path.

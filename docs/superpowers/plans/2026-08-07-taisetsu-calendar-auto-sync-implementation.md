# Taisetsu Calendar Auto Sync Implementation Plan

> **For implementation:** execute this plan directly on `main`; keep the user-provided Apple development team change and do not store account credentials.

**Goal:** Implement the approved automatic Calendar synchronization design for Taisetsu, including rolling occurrence generation, filtered sync scope, durable EventKit mappings, permission/status UX, exponential reminder prompts, localization, and CI-safe verification.

**Architecture:** Taisetsu remains the sole source of truth. A pure Core layer generates bounded future occurrences and evaluates category/tag scope. SwiftData stores sync settings and one mapping per managed occurrence. An EventKit adapter owns the dedicated `Taisetsu` calendar and exposes a testable client boundary. A main-actor sync service reconciles desired occurrences against mappings, while the app coordinator triggers reconciliation on lifecycle and data changes. A prompt coordinator handles first-save permission education with exponential backoff and a permanent opt-out.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, EventKit full access, WidgetKit, Swift Testing, XcodeGen, generated `.xcstrings` catalogs.

## Global constraints

- Preserve the user’s development team `2FBFFBNMS3` in both `project.yml` and the generated project; never commit the Apple ID or secrets.
- Keep all user-visible copy in the localization generator and regenerate catalogs for the ten existing locales.
- Do not use `EKRecurrenceRule`; create one managed `EKEvent` per occurrence, with a rolling two-year horizon, a 128-occurrence cap per anniversary, and a 1,000-event global cap prioritised by nearest occurrence.
- Deletions are limited to events represented by our persisted mapping; never delete an unowned EventKit event.
- Every behavior change is test-first: add a focused failing test, implement the smallest passing change, then run the relevant focused test before continuing.

## Task 1: Core occurrence window, scope filtering, and prompt backoff

**Files:** `TaisetsuCore/Domain/OccurrenceCalculator.swift`, new `TaisetsuCore/Domain/CalendarSyncScope.swift`, new `TaisetsuCore/Domain/CalendarSyncBackoff.swift`, `TaisetsuTests/OccurrenceCalculatorTests.swift`, new `TaisetsuTests/CalendarSyncScopeTests.swift`, new `TaisetsuTests/CalendarSyncBackoffTests.swift`.

1. Add a `ScheduledOccurrence` value (`sequence`, `date`) and a calculator API that returns occurrences in an inclusive `[start, end]` window, honoring one-time, Gregorian, and Chinese calendars plus all existing recurrence units. Stop at the requested per-record cap and guard invalid/non-advancing recurrences.
2. Add `CalendarSyncScope` with `.all` and `.custom(categories: Set<String>, tags: Set<String>, includeUncategorized: Bool, includeUntagged: Bool)`. Category matching is a single-category membership check; tag matching is a union check; when both filters are non-empty, use their intersection; explicit uncategorized/no-tags flags cover empty values.
3. Add deterministic `CalendarSyncBackoff`: immediate first prompt, then delays of 1/2/4/8/16/32/64 days, then 90-day intervals; persist attempt count and next eligible date; a permanent `neverRemind` state bypasses all eligibility checks.
4. Write tests for window boundaries, leap/Chinese dates, caps, scope truth tables, and every backoff transition. Run the focused Core tests.

## Task 2: SwiftData sync state and migration-safe repositories

**Files:** new `Taisetsu/Persistence/CalendarSyncModel.swift`, new `Taisetsu/Persistence/CalendarSyncRepository.swift`, `Taisetsu/Persistence/ModelContainerFactory.swift`, `Taisetsu/Persistence/AnniversaryModel.swift`, `TaisetsuTests/CalendarSyncRepositoryTests.swift`.

1. Add `CalendarSyncEntryModel` (`anniversaryID`, occurrence key, EventKit event ID, target calendar ID, occurrence date, last sync date, status, error message) and `CalendarSyncSettingsModel` (enabled, scope kind, category IDs, tag IDs, include-empty flags, horizon years, last successful sync, prompt state).
2. Include the models in the container schema and expose repository operations to load/save settings, upsert/delete entries by stable occurrence key, list entries by anniversary, and clear orphaned mappings.
3. Preserve `AnniversaryModel.calendarEventIdentifier` as a migration input. Add a migration helper that reuses an existing event identifier when it exists, moves/upserts it into the managed calendar, creates a new mapping, and clears the legacy field only after success; otherwise it creates a replacement without deleting unknown events.
4. Add in-memory SwiftData tests covering idempotent upsert, deletion, orphan cleanup, settings round-tripping, and legacy identifier migration.

## Task 3: EventKit adapter and automatic reconciliation engine

**Files:** `Taisetsu/Integrations/EventStoreClient.swift`, `Taisetsu/Integrations/CalendarExportService.swift` (compatibility update or replacement), new `Taisetsu/Integrations/CalendarAutoSyncService.swift`, `TaisetsuTests/CalendarAutoSyncServiceTests.swift`, update `TaisetsuTests/CalendarExportServiceTests.swift`.

1. Replace the narrow export-only protocol with a testable main-actor boundary for authorization state, full-access request, dedicated-calendar lookup/creation, event upsert/update, event existence checks, and managed-event deletion. Implement it with EventKit and `EKAuthorizationStatus`, using `NSCalendarsFullAccessUsageDescription`.
2. Implement `CalendarAutoSyncService.reconcile(records:now:settings:)`: ensure access and the `Taisetsu` calendar, generate each record’s bounded desired occurrences, apply scope, sort by date, enforce global cap, upsert desired entries, remove mappings no longer desired, and retain partial-success/error state. Never use EventKit recurrence rules.
3. Ensure repeated reconciliation is idempotent, updates changed drafts, recreates missing managed events, moves legacy events when possible, and does not touch unowned events. Expose a retry operation and a compact sync summary for settings/detail UI.
4. Add a spy-client test suite for permission states, calendar creation, create/update/delete, filtering, caps, missing events, partial errors, and idempotency.

## Task 4: App lifecycle, first-save prompt, settings/status UI, and localization

**Files:** `Taisetsu/App/AppDependencies.swift`, `Taisetsu/App/AppRootView.swift`, `Taisetsu/Coordination/ReconciliationCoordinator.swift`, `Taisetsu/Features/Home/HomeView.swift`, `Taisetsu/Features/Editor/AnniversaryEditorView.swift`, `Taisetsu/Features/Detail/AnniversaryDetailView.swift`, `Taisetsu/Features/Settings/SettingsView.swift`, new prompt/scope views as needed, `project.yml`, `scripts/generate-localizations.swift`, generated localization catalogs, `TaisetsuUITests/TaisetsuUITests.swift`.

1. Wire the sync repository/service into app dependencies and coordinator reconciliation. Trigger on launch/foreground, create/update/delete, scope changes, and permission changes; keep background refresh best-effort. Preserve reminder scheduling and existing snapshot behavior.
2. Add a prompt coordinator: after the first important-day save, present enable/later/never-remind actions immediately; later uses the backoff schedule. “Never remind again” is stored locally on-device. Enable requests full access and reconciles; denial/error remains visible with retry and system-settings actions.
3. Replace manual-export wording/actions with automatic-sync status. Add a Settings calendar sync card showing green/red/orange/blue state, target calendar, managed event count, last success, scope summary, retry, stop-sync, and system settings. Add a scope editor with all/custom, category multi-select, tag multi-select, uncategorized/no-tags options, expected event count, and rolling horizon.
4. Update the editor/detail/home callbacks so save/delete changes reconcile immediately and the smallest widget continues to show multiple nearest anniversaries. Keep the existing wheel date controls.
5. Add all new copy and updated Calendar usage text to the localization generator, regenerate catalogs, and add UI tests for status states, scope navigation, prompt actions, and localized app names (`重要日` for Chinese, `Taisetsu` elsewhere).

## Task 5: Project, CI, verification, and delivery

**Files:** `project.yml`, generated `Taisetsu.xcodeproj`, `scripts/verify.sh`, CI workflow files as needed.

1. Set the project team to `2FBFFBNMS3`, regenerate Xcode project/localizations, and verify no account email or secrets are present.
2. Extend CI/verification gates for the new tests and generated-file drift. Run formatter checks, localization checks, Core/app/widget tests, UI tests where the simulator is available, and the complete `scripts/verify.sh` gate.
3. Review the diff for unrelated changes, run `git diff --check`, commit the implementation and the intentional team/project metadata change on `main`, and push `main` to the public GitHub repository. Report the commit, verification evidence, and any Apple-side release prerequisites separately.

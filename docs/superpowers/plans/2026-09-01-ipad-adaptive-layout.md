# iPad Adaptive Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Taisetsu a native, polished iPad interface while keeping the iPhone experience and all product behavior intact.

**Architecture:** Select root navigation from horizontal size class, use a shared adaptive layout policy for content-width decisions, and compose existing feature content into bounded one- or two-column surfaces. Keep existing repositories, view models, navigation stacks, and localization keys.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, XCTest UI tests, iOS/iPadOS 18+

**Spec:** `docs/superpowers/specs/2026-09-01-ipad-adaptive-layout-design.md`

## Global constraints

- `project.yml` remains the project structure source of truth; run `xcodegen generate` after adding source files.
- Do not add dependencies, duplicate feature state, or query repositories from SwiftUI render paths.
- Preserve the five supported locales and reuse existing localized keys.
- Keep compact-width navigation and interaction behavior unchanged.
- Use native SwiftUI navigation, list, form, search, toolbar, and presentation behavior.

### Task 1: Protect the root navigation behavior

**Files:**
- Modify: `TaisetsuUITests/TaisetsuUITests.swift`
- Modify: `Taisetsu/App/AppRootView.swift`

- [x] Add an iPad-only UI test that launches in landscape, verifies `app-sidebar`, navigates through the three sidebar rows, and confirms the root tab bar is absent.
- [x] Run the focused test on the iPad Pro 13-inch simulator and verify RED because the current app has no sidebar.
- [x] Add an `AppSection` selection model and switch the root between compact `TabView` and regular `NavigationSplitView`.
- [x] Run the focused test again and verify GREEN; run the existing iPhone localization navigation test to prove tabs remain intact.

### Task 2: Add the shared adaptive layout policy

**Files:**
- Create: `Taisetsu/Shared/AdaptiveLayout.swift`
- Create: `TaisetsuTests/AdaptiveLayoutTests.swift`
- Regenerate: `Taisetsu.xcodeproj/project.pbxproj`

- [x] Add failing table-driven tests for the compact, regular-single-column, and regular-wide branches using hand-checked width inputs around the 920-point boundary.
- [x] Implement a small pure policy that derives column composition and exposes the dashboard/form width constants used by feature views.
- [x] Run the focused tests, then run `xcodegen generate` and an app build.

### Task 3: Adapt home and calendar composition

**Files:**
- Modify: `Taisetsu/Features/Home/HomeView.swift`
- Modify: `Taisetsu/Features/Calendar/CalendarView.swift`

- [x] Measure available feature width with `GeometryReader` and select composition through the shared policy.
- [x] Bound and center vertical home content; on wide regular width, place the hero beside one event-sections column.
- [x] Bound and center the calendar; on wide regular width, place the month grid beside the event panel while reusing one cached snapshot.
- [x] Build and run calendar snapshot/view-model tests to protect the existing render-time performance architecture.

### Task 4: Adapt form, detail, and editor surfaces

**Files:**
- Modify: `Taisetsu/Features/Detail/AnniversaryDetailView.swift`
- Modify: `Taisetsu/Features/Editor/AnniversaryEditorView.swift`
- Modify: `Taisetsu/Features/Settings/SettingsView.swift`
- Modify as needed: `Taisetsu/Features/Settings/CategoryManagerView.swift`
- Modify as needed: `Taisetsu/Features/Settings/TagManagerView.swift`

- [x] Center and cap list/form content at the shared readable form width while preserving system backgrounds and scrolling.
- [x] Use page-sized native editor presentation on regular width and automatic sizing on compact width.
- [x] Build and exercise create, edit, settings, category/tag, and calendar-sync paths on iPhone and iPad.

### Task 5: Verify behavior and visual quality

**Files:**
- Modify: `docs/superpowers/plans/2026-09-01-ipad-adaptive-layout.md`

- [x] Run focused adaptive unit tests and the focused iPad UI navigation test.
- [x] Run `bash scripts/verify.sh` and record test count and coverage.
- [x] Run the app on a 13-inch iPad simulator in portrait and landscape; inspect Home empty/content states, Calendar, Settings, detail, and editor.
- [x] Run an iPhone smoke test for root tabs and editor creation.
- [x] Record the final evidence in this plan and inspect `git diff --check` plus the complete diff before handoff.

## Final evidence

- `TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/verify.sh` exited 0 on 2026-09-01: build, localization, generated assets, formatting, 76 unit tests in 22 suites, 73 iPhone UI/launch-matrix tests (1 iPad-only skip), and the four selected critical UI flows all passed. TaisetsuCore line coverage was 94.15%.
- `testIPadUsesSidebarNavigation` passed on iPad Pro 13-inch (M4), iOS 18.6: 1 test, 0 failures. The same test correctly skips on iPhone by checking the device's short side.
- Manual visual QA covered iPad portrait and landscape Home empty/content states, Calendar split composition, Settings/readable forms, and the page-sized anniversary editor. iPhone root tabs, English localization, and create-from-empty-state behavior remained intact.
- `git diff --check` passed before handoff; the generated Xcode project contains the new shared layout source and tests.

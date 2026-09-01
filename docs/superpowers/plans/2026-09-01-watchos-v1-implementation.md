# watchOS V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a glanceable Apple Watch companion — complications, Smart Stack presence, reminder long-look, and a minimal browse surface — without changing any iPhone or iPad behavior.

**Architecture:** The watch is a read-only consumer of a snapshot pushed over WatchConnectivity, mirroring how `TaisetsuWidget` consumes the App Group snapshot. App Groups do not span devices, so the iPhone pushes `WatchSnapshot` and the watch persists it into its own App Group container for its widget extension. All date and selection logic lives in `TaisetsuCore` so the existing iOS test target covers it and the coverage gate keeps applying.

**Tech Stack:** Swift 6, SwiftUI, WidgetKit, WatchConnectivity, Swift Testing, iOS 18+, watchOS 11+

## Global constraints

- `project.yml` remains the project structure source of truth; run `xcodegen generate` after adding source files.
- `OccurrenceCalculator` stays the only source of dates. Surfaces render, they do not re-derive.
- `TaisetsuCore` must not import UIKit, WidgetKit, or WatchConnectivity; it compiles for both iOS and watchOS.
- The watch stays read-only in V1. No editor, no writes back to the phone.
- Preserve the five supported locales; watch strings are authored short rather than reused from iPhone.
- The iOS `Taisetsu` scheme now embeds the watch app, so every build environment needs watchOS platform support installed.

### Task 0: Verify the project generation and embedding shape

**Files:**
- Modify: `project.yml`
- Regenerate: `Taisetsu.xcodeproj/project.pbxproj`

- [x] Give `TaisetsuCore` `supportedDestinations: [iOS, watchOS]` rather than a second platform-suffixed target, so `coverage-check.sh` keeps finding `TaisetsuCore.framework`.
- [x] Add a `TaisetsuWatch` application target with `WKApplication`, the App Group entitlement, and `TARGETED_DEVICE_FAMILY: "4"`.
- [x] Embed the watch app from the iOS app into `$(CONTENTS_FOLDER_PATH)/Watch` and confirm the generated build phase uses `dstSubfolderSpec = 16`.
- [x] Install watchOS platform support (`xcodebuild -downloadPlatform watchOS`) and build the `TaisetsuWatch` scheme.

### Task 1: Move day math into one shared place

**Files:**
- Create: `TaisetsuCore/Domain/DayPresentation.swift`
- Create: `TaisetsuTests/DayPresentationTests.swift`
- Modify: `TaisetsuCore/Widget/WidgetSnapshot.swift`
- Modify: `TaisetsuWidget/TaisetsuWidgetView.swift`

- [x] Add `DayDirection`, `DayPresentation`, and `DayPresentationCalculator` covering the countdown, count-up, and clamped-past branches.
- [x] Delete the widget-local `WidgetDayDirection` and `WidgetDayPresentation` and delegate `WidgetEventSnapshot.dayPresentation` to the shared calculator.
- [x] Add a parity test proving the widget and watch surfaces agree for identical dates.

### Task 2: Model the watch snapshot

**Files:**
- Create: `TaisetsuCore/Watch/WatchSnapshot.swift`
- Create: `TaisetsuCore/Watch/WatchComplicationFamily.swift`
- Create: `TaisetsuTests/WatchSnapshotTests.swift`

- [x] Carry several upcoming occurrences per event so an offline watch rolls over on its own instead of showing a stale count.
- [x] Resolve the target occurrence with day granularity for all-day events, so today's event reads as 0 rather than rolling to next year at 00:01.
- [x] List every record in the watch app but filter complications by `isVisibleInWidget`; hiding an event from the home screen is about who can see the phone.
- [x] Cover ordering, lookahead, local rollover, past one-time fallback, capacity, and Codable round trip.

### Task 3: Model Smart Stack relevance

**Files:**
- Create: `TaisetsuCore/Watch/WatchRelevance.swift`
- Create: `TaisetsuTests/WatchRelevanceTests.swift`

- [x] Score by proximity buckets, add a pinned bonus, and clamp at the maximum.
- [x] Keep count-up events low priority; they have no deadline to compete for.
- [x] Expire the relevance window at the next local midnight, when day buckets can change.

### Task 4: Push the snapshot from iPhone to watch

**Files:**
- Create: `Taisetsu/Integrations/WatchTransport.swift`
- Create: `TaisetsuTests/WatchTransportTests.swift`
- Modify: `Taisetsu/Coordination/ReconciliationPlan.swift`
- Modify: `Taisetsu/Coordination/ReconciliationCoordinator.swift`

- [x] Add a `WatchTransport` protocol with a `WCSession` implementation, so reconciliation can be tested against a fake.
- [x] Extend `ReconciliationPlan` with `watchSnapshot`, mirroring the existing `includesWidgetSnapshot` switch.
- [x] Send every reconcile through `updateApplicationContext`, and only spend `transferCurrentComplicationUserInfo` when the snapshot content hash changes; the complication transfer has a daily budget.
- [x] Verify the transport is skipped entirely when the session is unsupported or no watch is paired.

### Task 5: Receive and persist on the watch

**Files:**
- Create: `TaisetsuWatch/App/WatchSnapshotStore.swift`
- Create: `TaisetsuWatch/App/WatchSessionReceiver.swift`
- Modify: `TaisetsuWatch/App/TaisetsuWatchApp.swift`

- [x] Write the received snapshot atomically into the watch App Group container, reusing the `WidgetSnapshotStore` file-protection options.
- [x] Reload complication timelines after a successful write.
- [x] Reject snapshots whose `schemaVersion` does not match, exactly as the iOS widget provider does.
- [x] Rely on application-context persistence instead of an explicit first-launch request: the system
      retains the most recent context and delivers it when the watch app becomes reachable, so the
      extra request/reply round trip would only duplicate it.

### Task 6: Build the watch browse surface

**Files:**
- Create: `TaisetsuWatch/Features/WatchHomeView.swift`
- Create: `TaisetsuWatch/Features/WatchDetailView.swift`
- Create: `TaisetsuWatch/Features/WatchEmptyView.swift`
- Modify: `TaisetsuWatch/App/WatchRootView.swift`

- [x] One event per screen in a vertically paged `TabView`; do not port the iPhone information density.
- [x] Handle the `taisetsu://anniversary/<id>` deep link from complications.
- [x] Degrade under `isLuminanceReduced`: drop colour and animation, keep the number and title.
- [x] Show an empty state that names the iPhone as the place to add an event.

### Task 7: Ship the complications

**Files:**
- Create: `TaisetsuWatchWidget/*`
- Modify: `project.yml`

- [x] Support `.accessoryCircular`, `.accessoryCorner`, `.accessoryInline`, and `.accessoryRectangular`.
- [x] Emit one entry per day for the next eight days rather than `Text(timerInterval:)`: the count is
      day-granular, so pre-rendered daily entries advance it without ever waking the extension.
- [x] Anchor each entry at the next local 00:01, matching `TaisetsuProvider`.
- [x] Attach `TimelineEntryRelevance` from `WatchRelevance` so the Smart Stack surfaces the card on the day itself.

### Task 8: Custom reminder long-look

**Files:**
- Modify: `Taisetsu/Integrations/NotificationCenterClient.swift`
- Create: `TaisetsuWatch/Notifications/ReminderController.swift`
- Modify: `TaisetsuWatch/App/TaisetsuWatchApp.swift`

- [x] Set a `categoryIdentifier` on scheduled reminder content; it is currently absent and is the prerequisite for a custom long-look.
- [x] Register a `WKNotificationScene` bound to that category.
- [ ] Verify a forwarded reminder renders the custom long-look and its deep link opens the right event.
      Needs a paired device or a phone+watch simulator pair; not covered by the automated suite.

### Task 9: Localize and close the gates

**Files:**
- Create: `TaisetsuWatch/Resources/Localizable.xcstrings`
- Create: `TaisetsuWatchWidget/Resources/Localizable.xcstrings`
- Modify: `scripts/localization-check.sh`
- Modify: `scripts/verify.sh`, `.github/workflows/ci.yml`

- [x] Add the watch targets to the drift check, the formatter, and a watch build step in both `verify.sh` and CI.
- [x] Install watchOS platform support in CI before building the iOS scheme, which now embeds the watch app.
- [x] Add both watch catalogs to `localization-check.sh` and translate all five locales.
- [x] Watch for the "translation matches its English source" gate; short watch strings collide easily and either need different wording or an entry in the intentional-match list.
- [x] Add a watchOS app icon asset catalog.
- [x] Extend `scripts/generate-app-icon.swift` to emit the watch catalog and its `Contents.json`
      from the same render, so the watch icon can never drift from a hand copy.
- [x] Add a circular safe-area assertion to `scripts/app-icon-design-check.swift`: watchOS clips to
      the inscribed circle, and the iOS and watch icons share one render, so an iOS-only design
      change could otherwise silently clip on the wrist. The mark currently reaches 43.7 of the 60
      unit radius; the contract holds it within 54.
- [x] Update `README.md` and `docs/brand-localization.md` with the watch target and its bundle identifiers.

## Runtime verification

Verified on a paired iPhone 17 Pro + Apple Watch Series 11 (46mm) simulator pair, watchOS 26.5:

- The watch app launches, renders the empty state, and picks up `zh-Hans` from the device locale.
- Creating an anniversary on the iPhone produced `watch-events.json` in the *watch's* App Group
  container, and the watch app rendered it — snapshot build, WatchConnectivity delivery, watch-side
  decode and persistence all work end to end.
- An all-day event occurring today reads `0` at 16:16 local, confirming the day-granularity target
  resolution rather than a naive instant comparison.
- `chronod` requested and rendered timelines for every declared accessory family with no errors.

One defect this surfaced that no build or unit test could: XcodeGen emits **no**
`LD_RUNPATH_SEARCH_PATHS` for watchOS application targets, so the app shipped with only
`@executable_path` and dyld aborted at launch looking for `TaisetsuCore.framework` beside the
executable instead of inside `Frameworks/`. The setting is now pinned explicitly in `project.yml`.

Still unverified: the reminder long-look, which needs a notification actually delivered to the
paired watch.

## Deferred to V2

Milestone engine, Digital Crown time travel with haptic detents, "thought of you" check-ins, haptic signatures per category, and any watch-side editing. V1 earns the wrist; V2 earns the differentiation.

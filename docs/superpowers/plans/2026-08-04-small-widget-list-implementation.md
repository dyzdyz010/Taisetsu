# Small Widget Event List Implementation Plan

> **Execution:** Work directly on `main` per the repository workflow. Keep data selection changes test-first, then verify the WidgetKit view by formatting, building the extension through the app scheme, and running the full test suite.

**Goal:** Replace the single-event small widget with an accessible three-row list whose rows open their own anniversary details.

**Architecture:** Keep `WidgetSnapshot` as the single family-capacity and ordering source. The small WidgetKit view consumes the first three snapshot events and renders each inside a `Link`; medium and large retain their existing list and whole-widget URL behavior. No snapshot schema migration is needed.

**Tech Stack:** Swift 6, SwiftUI, WidgetKit, Swift Testing, String Catalogs.

---

## Task 1: Increase the small-family snapshot capacity

**Files:**

- Modify: `TaisetsuTests/WidgetSelectionTests.swift`
- Modify: `TaisetsuCore/Widget/WidgetSnapshot.swift`

1. Rename the family-capacity test to describe three, four, and five results; change the small expectation from one to three.
2. Run only `WidgetSelectionTests` and confirm the capacity test fails with an actual count of one.
3. Change `WidgetSnapshotFamily.small.capacity` to three.
4. Re-run `WidgetSelectionTests` and confirm all widget selection and deep-link tests pass.

## Task 2: Render an independently tappable three-row small widget

**Files:**

- Modify: `TaisetsuWidget/TaisetsuWidgetView.swift`
- Modify: `TaisetsuWidget/TaisetsuWidget.swift`

1. Replace the single-event `smallView` with a list that renders all selected small-family events.
2. Give each row a minimum 44-point height and show the category icon, one-line title, optional pin, and one-line relative date.
3. Wrap each row in `Link(destination: event.deepLink)` when the deep link is valid.
4. Apply `widgetURL` only to medium and large families so a small-widget row cannot route to the first event accidentally.
5. Expand the placeholder snapshot to three distinct records so the widget gallery demonstrates the final small layout.

## Task 3: Complete widget accessibility localization

**Files:**

- Modify: `scripts/generate-localizations.swift`
- Generate: `TaisetsuWidget/Resources/Localizable.xcstrings`

1. Add `Pinned` to the widget catalog in all supported locales.
2. Combine each row into one VoiceOver element that announces its full title, relative date, and pinned state.
3. Regenerate String Catalogs and run the localization consistency checks.

## Task 4: Verify, review, commit, and push

**Files:**

- Review all files modified above.

1. Run `git diff --check` and Swift format lint.
2. Run `bash scripts/verify.sh` to regenerate the project, validate localizations, build the app and widget extension, run unit tests, and enforce coverage.
3. Inspect the final diff for family behavior, localization coverage, accessibility, and unrelated changes.
4. Commit the implementation on `main`, push to `origin/main`, and confirm the worktree is clean and local `HEAD` matches the remote.


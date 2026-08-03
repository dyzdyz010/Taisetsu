# Wheel Date and Recurrence Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace numeric date fields with native three-column wheels and express recurrence as “每 [数量] [单位]”.

**Architecture:** Keep the existing `AnniversaryDraft` persistence contract. Add small, testable normalization helpers beside the two editor sections, then bind SwiftUI system controls directly to the draft so no migration or repository change is required.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, XCTest UI testing, XcodeGen, iOS 18+

## Global Constraints

- Preserve Gregorian and Chinese-lunar semantics, including optional leap months.
- Keep recurrence intervals in the existing 1 through 999 UI range.
- Use only native SwiftUI controls and existing project dependencies.
- Do not modify the persistence schema, reminder scheduling, recurrence semantics, or widget schema. Correct exact lunar date resolution if the wheel exposes an existing boundary mismatch.

---

### Task 1: Lock the new interaction contract with failing tests

**Files:**
- Modify: `TaisetsuTests/AnniversaryEditorViewModelTests.swift`
- Modify: `TaisetsuUITests/TaisetsuUITests.swift`

**Interfaces:**
- Consumes: `AnniversaryDate`, `CalendarKind`, the real anniversary editor UI.
- Produces: regression coverage for date normalization and stable accessibility identifiers.

- [ ] **Step 1: Add a unit test for Gregorian day normalization**

```swift
@Test func dateWheelClampsGregorianDayWhenMonthOrYearChanges() {
    var date = AnniversaryDate(year: 2024, month: 2, day: 31)
    DateWheelSelection.normalize(&date, calendarKind: .gregorian)
    #expect(date.day == 29)

    date.year = 2023
    DateWheelSelection.normalize(&date, calendarKind: .gregorian)
    #expect(date.day == 28)
}
```

- [ ] **Step 2: Add a unit test for recurrence toggle normalization**

```swift
@Test func recurrenceToggleUsesYearlyDefaultAndCanonicalNoneState() {
    var draft = AnniversaryDraft()
    RecurrenceEditorSelection.setEnabled(true, draft: &draft)
    #expect(draft.recurrenceUnit == .year)
    #expect(draft.recurrenceInterval == 1)

    draft.recurrenceInterval = 3
    RecurrenceEditorSelection.setEnabled(false, draft: &draft)
    #expect(draft.recurrenceUnit == nil)
    #expect(draft.recurrenceInterval == 1)
}
```

- [ ] **Step 3: Add a UI test for the real controls**

```swift
@MainActor
func testEditorUsesDateWheelsAndStructuredRecurrenceControls() throws {
    let app = makeApplication()
    app.launch()
    app.buttons["add-anniversary"].tap()

    XCTAssertTrue(app.pickers["date-wheel-year"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.pickers["date-wheel-month"].exists)
    XCTAssertTrue(app.pickers["date-wheel-day"].exists)

    let recurrenceToggle = app.switches["recurrence-enabled"]
    XCTAssertTrue(recurrenceToggle.exists)
    recurrenceToggle.tap()
    XCTAssertTrue(app.steppers["recurrence-interval"].exists)
    XCTAssertTrue(app.buttons["recurrence-unit"].exists)
}
```

- [ ] **Step 4: Run the tests and verify RED**

Run: `bash scripts/ci-test.sh`

Expected: compilation fails because `DateWheelSelection` and `RecurrenceEditorSelection` do not exist.

---

### Task 2: Implement the three-column date wheel

**Files:**
- Modify: `Taisetsu/Features/Editor/DateRuleSection.swift`
- Test: `TaisetsuTests/AnniversaryEditorViewModelTests.swift`

**Interfaces:**
- Consumes: `Binding<AnniversaryDraft>` and `AnniversaryDate`.
- Produces: `DateWheelSelection.normalize(_:calendarKind:)` and the three wheel pickers.

- [ ] **Step 1: Add `DateWheelSelection`**

Implement year ranges that include the selected year, Gregorian month lengths, Chinese month lengths derived from `Calendar(identifier: .chinese)`, and in-place day clamping.

- [ ] **Step 2: Replace the year field and month/day steppers**

Render `Picker` controls for year, month, and day in one `HStack`, apply `.pickerStyle(.wheel)`, and set identifiers `date-wheel-year`, `date-wheel-month`, and `date-wheel-day`.

- [ ] **Step 3: Normalize after relevant selections change**

Call the helper when calendar kind, year, month, or leap-month state changes so the day selection never points outside the visible wheel range.

- [ ] **Step 4: Run unit tests and verify GREEN**

Run: `bash scripts/ci-test.sh`

Expected: all unit tests pass.

---

### Task 3: Implement structured recurrence controls

**Files:**
- Modify: `Taisetsu/Features/Editor/RecurrenceSection.swift`
- Test: `TaisetsuTests/AnniversaryEditorViewModelTests.swift`
- Test: `TaisetsuUITests/TaisetsuUITests.swift`

**Interfaces:**
- Consumes: `Binding<AnniversaryDraft>`.
- Produces: `RecurrenceEditorSelection.setEnabled(_:draft:)`, a repeat toggle, interval stepper, and unit menu.

- [ ] **Step 1: Add `RecurrenceEditorSelection`**

Enabling an empty rule sets unit `.year` and interval `1`; disabling clears the unit and resets interval to `1`.

- [ ] **Step 2: Replace the ambiguous unit-first picker**

Show a `Toggle` with identifier `recurrence-enabled`. When enabled, show “每”, the current numeric interval, a menu containing “天、周、月、年”, and a trailing Stepper with range `1...999`.

- [ ] **Step 3: Add stable accessibility values**

Set identifiers `recurrence-interval` and `recurrence-unit`, and expose the composed phrase as an accessibility value such as “每 2 月”.

- [ ] **Step 4: Run unit and UI tests and verify GREEN**

Run: `TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh`

Expected: all unit and UI tests pass.

---

### Task 4: Harden Gregorian anchors and lunar boundary resolution

**Files:**
- Modify: `Taisetsu/Domain/AnniversaryDraft.swift`
- Modify: `Taisetsu/Features/Editor/DateRuleSection.swift`
- Modify: `TaisetsuCore/Domain/OccurrenceCalculator.swift`
- Test: `TaisetsuTests/AnniversaryEditorViewModelTests.swift`
- Test: `TaisetsuTests/OccurrenceCalculatorTests.swift`

**Interfaces:**
- Consumes: the Gregorian anchor-year contract and Chinese-calendar month/day components.
- Produces: system-calendar-independent year defaults and exact lunar day resolution at Gregorian-year boundaries.

- [ ] **Step 1: Add regression tests**

Verify that a new draft and wheel range use Gregorian year 2026 for a known 2026 instant, and that lunar `2026/11/1` resolves to the exact lunar day on 2026-12-09 rather than indexing from 2026-01-01.

- [ ] **Step 2: Use explicit Gregorian calendars for anchor years**

Construct Gregorian calendars with the requested local time zone in both `AnniversaryDraft` and `DateWheelSelection`.

- [ ] **Step 3: Match lunar day components exactly**

Resolve the selected ordinary or leap month as the complete logical month whose first day is in the Gregorian anchor year. If the same numbered month starts twice in one anchor year, retain the first start for backward compatibility. Share that metadata with the wheel, fall back to the ordinary month when the requested leap month does not begin in the anchor year, and retain month-end clamping for legacy invalid dates.

- [ ] **Step 4: Verify RED/GREEN**

Run the boundary test against the previous resolver to confirm the failure, restore the exact-match implementation, then run the full unit suite.

---

### Task 5: Verify and publish

**Files:**
- Verify all modified Swift, test, and documentation files.

**Interfaces:**
- Consumes: the completed controls and tests.
- Produces: a clean feature branch with reproducible project output and passing CI.

- [ ] **Step 1: Run the complete local quality gate**

Run: `TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/verify.sh`

Expected: generation has no drift, formatting passes, all targets build, all tests pass, and TaisetsuCore coverage remains at or above 80%.

- [ ] **Step 2: Review the diff**

Run: `git diff --check && git status --short`

Expected: no whitespace errors and only planned files changed.

- [ ] **Step 3: Commit and push the feature branch**

```bash
git add docs/superpowers Taisetsu/Domain Taisetsu/Features/Editor TaisetsuCore/Domain TaisetsuTests TaisetsuUITests
git commit -m "feat: clarify date and recurrence controls"
git push -u origin feat/wheel-date-recurrence
```

- [ ] **Step 4: Open the pull request and wait for all required checks**

Require the full CI, UI smoke test, dependency review, and Swift CodeQL checks before merging.

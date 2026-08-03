# Wheel Date and Recurrence Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace numeric date fields with native three-column wheels and express recurrence as “每 [数量] [单位]”.

**Architecture:** Keep the existing `AnniversaryDraft` persistence contract. Add small, testable normalization helpers beside the two editor sections, then bind SwiftUI system controls directly to the draft so no migration or repository change is required.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, XCTest UI testing, XcodeGen, iOS 18+

## Global Constraints

- Preserve Gregorian and Chinese-lunar semantics, including optional leap months.
- Keep recurrence intervals in the existing 1 through 999 UI range.
- Use only native SwiftUI controls and existing project dependencies.
- Do not modify the persistence schema, reminder scheduling, occurrence calculation, or widget schema.

---

### Task 1: Lock the new interaction contract with failing tests

**Files:**
- Modify: `LifeTimerTests/AnniversaryEditorViewModelTests.swift`
- Modify: `LifeTimerUITests/LifeTimerUITests.swift`

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
- Modify: `LifeTimer/Features/Editor/DateRuleSection.swift`
- Test: `LifeTimerTests/AnniversaryEditorViewModelTests.swift`

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
- Modify: `LifeTimer/Features/Editor/RecurrenceSection.swift`
- Test: `LifeTimerTests/AnniversaryEditorViewModelTests.swift`
- Test: `LifeTimerUITests/LifeTimerUITests.swift`

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

Run: `LIFETIMER_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh`

Expected: all unit and UI tests pass.

---

### Task 4: Verify and publish

**Files:**
- Verify all modified Swift, test, and documentation files.

**Interfaces:**
- Consumes: the completed controls and tests.
- Produces: a clean feature branch with reproducible project output and passing CI.

- [ ] **Step 1: Run the complete local quality gate**

Run: `LIFETIMER_INCLUDE_UI_TESTS=1 bash scripts/verify.sh`

Expected: generation has no drift, formatting passes, all targets build, all tests pass, and LifeTimerCore coverage remains at or above 80%.

- [ ] **Step 2: Review the diff**

Run: `git diff --check && git status --short`

Expected: no whitespace errors and only planned files changed.

- [ ] **Step 3: Commit and push the feature branch**

```bash
git add docs/superpowers LifeTimer/Features/Editor LifeTimerTests LifeTimerUITests
git commit -m "feat: clarify date and recurrence controls"
git push -u origin feat/wheel-date-recurrence
```

- [ ] **Step 4: Open the pull request and wait for all required checks**

Require the full CI, UI smoke test, dependency review, and Swift CodeQL checks before merging.

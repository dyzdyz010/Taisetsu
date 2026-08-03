# Lunar Recurrence Clarity Design

**Date:** 2026-08-03

**Status:** Approved for implementation

## Problem

A record entered as lunar 1992 month 8 day 4 appeared with its next occurrence on 2026-08-16, which is lunar month 7 day 4. Inspection of the persisted record showed that the date itself was stored correctly, while its recurrence was `month` with interval `6`. The occurrence engine also resolves the intended yearly case correctly: lunar month 8 day 4 falls on 2026-09-14 in Asia/Shanghai.

The defect is therefore not lunar conversion. It is an avoidable semantic ambiguity: a lunar month interval advances through logical lunar months, including leap months, so it does not promise the same numbered lunar month in future years. The editor and detail UI do not expose this consequence clearly enough.

## Decision

Preserve all existing recurrence units for both Gregorian and Chinese-lunar records. Do not silently reinterpret or migrate legitimate monthly records. Improve the UI so the selected rule and its calculated consequence are visible before and after saving.

For a Chinese-lunar record whose recurrence unit is `month`:

- Show a localized explanatory note that leap months count in the interval and a future occurrence can have a different lunar month number.
- Show a live next-occurrence preview in the editor using the real `OccurrenceCalculator`.
- Present the preview with both its localized Gregorian date and localized lunar month/day.

The detail screen shows lunar month/day alongside the existing Gregorian original and next-occurrence dates for every Chinese-lunar record.

## Components

`AnniversaryFormatters` owns localized lunar month/day formatting and the combined Gregorian-plus-lunar presentation. It derives lunar components with `Calendar(identifier: .chinese)`, respects the supplied time zone, and distinguishes ordinary and leap months.

`RecurrencePreview` converts an `AnniversaryDraft` into the minimal real `AnniversaryRecord` needed by `OccurrenceCalculator`. Invalid or incomplete dates return no preview rather than breaking the editor.

`RecurrenceSection` renders the live next occurrence and the lunar-month explanation. `AnniversaryDetailView` reuses the same formatter for stored records so editor and detail semantics cannot drift.

## Localization

All new labels, lunar templates, and the lunar-month explanation are added to the deterministic localization generator for the existing eleven launch locales. User-entered titles remain untouched.

## Data Safety

There is no schema change and no automatic mutation of existing records. A user who intended an annual lunar anniversary must explicitly choose `Every 1 Year`. This prevents a heuristic migration from corrupting legitimate monthly schedules.

## Verification

- A core regression test proves lunar 1992 month 8 day 4 repeated yearly resolves next to 2026-09-14 in Asia/Shanghai.
- App tests prove a six-month lunar recurrence previews 2026-08-16 as lunar month 7 day 4 and exposes the explanatory note condition.
- Formatter tests cover ordinary and leap lunar month/day output without deriving expected values from production helpers.
- Existing recurrence, localization, build, unit-test, coverage, and UI smoke gates remain green.

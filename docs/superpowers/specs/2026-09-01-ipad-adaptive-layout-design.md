# iPad Adaptive Layout Design

## Goal

Make Taisetsu feel intentionally designed for iPad while preserving the existing iPhone experience. The adaptation must use native iPad navigation, readable content widths, and useful multi-column composition without changing the product model or adding tablet-only features.

## Evidence

Visual QA on a 13-inch iPad Pro simulator found no broken controls, but the current interface scales the iPhone hierarchy across the full canvas:

- the root tabs move to a wide top bar without offering persistent app-level navigation;
- the home hero stretches across the display and leaves a large unused region;
- the calendar grid and weekday columns become unnecessarily distant;
- settings and detail forms use lines that are too long for comfortable reading;
- the editor remains a narrow form presentation and underuses the iPad canvas.

## Selected direction

### Navigation

- Compact horizontal size class keeps the current three-tab `TabView`.
- Regular horizontal size class uses a native `NavigationSplitView` with a collapsible sidebar for Home, Calendar, and Settings.
- The sidebar uses system symbols, system selection behavior, and a balanced split style. It stays visible in wide landscape layouts and can collapse in portrait or multitasking.
- Each feature keeps its own `NavigationStack`, so existing detail navigation, search, toolbars, and sheets remain intact.

### Shared layout rules

- Center reading surfaces instead of stretching them edge to edge.
- Use 24-point regular-width margins and a 28-point gap between major columns.
- Cap dashboard-style content around 1,040 points and form-style content around 760 points.
- Switch to two columns only when the feature's available detail width is at least 920 points. This makes the layout respond correctly to split-screen widths, not merely to device type or orientation.
- Keep system type, Dynamic Type behavior, native lists/forms, semantic colors, and minimum touch targets. No custom navigation chrome or fixed text sizes are introduced.

### Home

- Compact and narrower regular widths keep the vertical hero-then-sections flow.
- Wide regular widths place the hero in a calm leading column and all event sections in a flexible trailing column.
- The hero receives a bounded width; event rows retain their existing actions, navigation, and ordering.
- Empty, loading, and error states use a centered readable region rather than the entire canvas.

### Calendar

- Compact and narrower regular widths keep the month grid above the month's events.
- Wide regular widths place the bounded calendar grid beside a secondary event panel.
- `CalendarMonthSnapshot` remains the single render-time projection. Layout branching must reuse one snapshot and must not introduce repository access or occurrence calculation in `body`.

### Forms, detail, and editor

- Settings, category/tag management, calendar-sync settings, and anniversary detail use a centered form width.
- Editor sheets use the native page presentation on regular width and automatic presentation on compact width. The form itself remains bounded and centered.
- All current labels, fields, validation, focus order, keyboard toolbar actions, and save behavior remain unchanged.

## Accessibility and localization

- Sidebar rows expose stable accessibility identifiers for UI verification.
- The same localized keys used by the iPhone tabs are used by the iPad sidebar; no new user-facing copy is required.
- Layout must remain usable with larger text, dark appearance, reduced motion, keyboard navigation, and VoiceOver reading order.
- The supported locale set remains exactly English, Simplified Chinese, Traditional Chinese, Norwegian Bokmål, and German.

## Acceptance

1. iPhone continues to show Home, Calendar, and Settings as bottom tabs.
2. iPad regular width shows native sidebar navigation and no root tab bar.
3. Sidebar selection switches among all three feature roots without losing existing feature behavior.
4. Home and calendar adopt two-column layouts only when their available width can support them.
5. List/form/detail/editor content no longer spans an excessively wide iPad canvas.
6. Existing build, unit, localization, icon, and coverage gates pass.
7. Focused iPad UI navigation test passes, followed by portrait and landscape visual QA on the 13-inch iPad simulator.

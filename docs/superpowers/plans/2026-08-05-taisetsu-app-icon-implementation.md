# Taisetsu App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the ornate hourglass with the approved three-shape Taisetsu icon and ship deterministic default, dark, and tinted iOS assets.

**Architecture:** A standalone Swift generator owns the approved geometry and palettes, renders an auditable SVG master plus three opaque 1024-pixel PNGs, and can compare committed outputs against fresh renders. A shell contract verifies Asset Catalog assignment and invokes generator drift checking; local and GitHub verification run that contract before building.

**Tech Stack:** Swift 6, CoreGraphics, ImageIO, SVG, Asset Catalog JSON, Bash, jq, Xcode 26.6.

## Global Constraints

- Work directly on `main`, create no pull request, and push only after local verification passes.
- Use one `120 × 120` geometry for every appearance: two 8-unit round-capped curves and a circle centered at `(60, 61)` with radius `13`.
- Default palette is `#F1ECE4`, `#303047`, `#D95C49`.
- Dark palette is `#252743`, `#F1ECE4`, `#E56D59`.
- Tinted palette is `#DED6CC`, `#453C45`, with the center dot rendered at 42% foreground opacity over the opaque background.
- All PNGs are 1024 × 1024, sRGB, and contain no alpha channel; the source artwork contains no rounded mask, shadow, glow, gradient, texture, text, or external asset.
- Preserve one generated SVG master and make generated output drift fail verification.
- Normalize only Xcode extraction metadata in generated string catalogs; do not introduce localization content changes.

---

### Task 1: Add the failing app-icon asset contract

**Files:**

- Create: `scripts/app-icon-check.sh`
- Modify: `scripts/verify.sh`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**

- Consumes: `Taisetsu/Assets.xcassets/AppIcon.appiconset/Contents.json`, the three PNG files, `Design/AppIcon/TaisetsuAppIcon.svg`, and `scripts/generate-app-icon.swift --check`.
- Produces: a nonzero exit for missing/misassigned files, wrong dimensions, alpha-bearing PNGs, or generated-output drift.

- [ ] **Step 1: Write the asset contract before creating new assets**

Create an executable Bash script with `set -euo pipefail`. Use `jq -e` to require these exact filename assignments:

```jq
(.images | map(select(.appearances == null))[0].filename == "AppIcon.png") and
(.images | map(select(.appearances[0].value == "dark"))[0].filename == "AppIcon-Dark.png") and
(.images | map(select(.appearances[0].value == "tinted"))[0].filename == "AppIcon-Tinted.png")
```

For every PNG, use `sips -g pixelWidth -g pixelHeight -g hasAlpha` and require `1024`, `1024`, and `no`. Require the SVG master to exist, then run:

```bash
swift scripts/generate-app-icon.swift --check
```

Add `bash scripts/app-icon-check.sh` after localization validation in `scripts/verify.sh`, and add a `Check application icon assets` CI step after localization validation in both macOS jobs.

- [ ] **Step 2: Run the contract and verify RED**

Run: `bash scripts/app-icon-check.sh`

Expected: FAIL with `Missing app icon asset: AppIcon-Dark.png` because the approved dark and tinted assets do not exist yet.

- [ ] **Step 3: Commit the failing contract**

```bash
git add scripts/app-icon-check.sh scripts/verify.sh .github/workflows/ci.yml
git commit -m "test: enforce app icon asset contract"
```

### Task 2: Generate the approved vector and raster assets

**Files:**

- Create: `scripts/generate-app-icon.swift`
- Create: `Design/AppIcon/TaisetsuAppIcon.svg`
- Replace: `Taisetsu/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Create: `Taisetsu/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png`
- Create: `Taisetsu/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png`
- Modify: `Taisetsu/Assets.xcassets/AppIcon.appiconset/Contents.json`

**Interfaces:**

- Consumes: no third-party runtime or design dependency.
- Produces: `swift scripts/generate-app-icon.swift` to write all committed artwork and `--check` to compare fresh output with the committed SVG, JSON, and decoded PNG pixels.

- [ ] **Step 1: Implement one geometry and three palettes**

Define `RGB`, `Palette`, and `Appearance` values in the Swift script. Render in a 120-unit CoreGraphics coordinate system scaled to 1024 pixels. Use these absolute cubic curves:

```swift
left.move(to: CGPoint(x: 45, y: 30))
left.addCurve(
    to: CGPoint(x: 29, y: 69),
    control1: CGPoint(x: 29, y: 40),
    control2: CGPoint(x: 25, y: 55)
)
left.addCurve(
    to: CGPoint(x: 49, y: 92),
    control1: CGPoint(x: 32, y: 79),
    control2: CGPoint(x: 39, y: 87)
)
```

Mirror the right curve around `x = 60`. Fill the center ellipse at `(47, 48, 26, 26)`. Render into an sRGB context with `CGImageAlphaInfo.noneSkipLast`, and write PNG data using `CGImageDestination` and `UTType.png`.

- [ ] **Step 2: Generate the SVG and Asset Catalog metadata from the same constants**

The SVG uses `width="1024" height="1024" viewBox="0 0 120 120"`, a full-canvas background rectangle, the approved path with round line caps, and the center circle. Generate `Contents.json` with filenames explicitly assigned to the Any, Dark, and Tinted slots.

- [ ] **Step 3: Implement drift checking**

For `--check`, render all outputs into a `FileManager` temporary directory. Compare SVG and JSON bytes directly. Decode committed and fresh PNGs with ImageIO, require 1024 × 1024 and no alpha, then compare their raw RGBA-normalized pixel buffers so PNG container metadata does not create false drift.

- [ ] **Step 4: Generate the new assets**

Run: `swift scripts/generate-app-icon.swift`

Expected: the command reports the SVG master and all three PNGs as written.

- [ ] **Step 5: Run the asset contract and verify GREEN**

Run: `bash scripts/app-icon-check.sh`

Expected: PASS and `App icon assets are complete and current.`

- [ ] **Step 6: Inspect rendered assets**

Render a contact sheet or open all three 1024-pixel PNGs. Confirm the shapes remain separated at 48 and 28 pixels, the source images have square corners, and there are no baked shadows or texture.

- [ ] **Step 7: Commit generated artwork**

```bash
git add Design/AppIcon/TaisetsuAppIcon.svg scripts/generate-app-icon.swift \
    Taisetsu/Assets.xcassets/AppIcon.appiconset
git commit -m "feat: replace Taisetsu app icon"
```

### Task 3: Normalize generated metadata and verify delivery

**Files:**

- Normalize: `Taisetsu/Resources/InfoPlist.xcstrings`
- Normalize: `Taisetsu/Resources/Localizable.xcstrings`
- Normalize: `TaisetsuWidget/Resources/Localizable.xcstrings`
- Verify: all files modified in Tasks 1 and 2

**Interfaces:**

- Consumes: the repository's localization generator, full verification gate, simulator build, and GitHub Actions workflows.
- Produces: verified icon assets on `origin/main` with no generated-catalog drift.

- [ ] **Step 1: Normalize Xcode-only extraction metadata**

Run: `swift scripts/generate-localizations.swift`

Expected: the three String Catalogs return to their deterministic committed form with no semantic copy changes and disappear from `git status`.

- [ ] **Step 2: Run the complete local verification gate**

Run: `bash scripts/verify.sh`

Expected: icon drift validation, project generation, naming checks, localization checks, Swift formatting, app and widget build, all unit tests, and coverage enforcement succeed.

- [ ] **Step 3: Inspect the built Asset Catalog**

Run a focused unsigned simulator build and require no `actool` warning about missing app-icon appearances, alpha channels, or unassigned children.

- [ ] **Step 4: Review repository scope**

```bash
git diff --check
git status --short --branch
git log --oneline --decorate -5
```

Expected: only intentional icon implementation commits are ahead of `origin/main`, and the worktree is clean.

- [ ] **Step 5: Push directly to main**

Run: `git push origin main`

Expected: `origin/main` advances to the icon implementation without a pull request.

- [ ] **Step 6: Require remote verification**

Monitor the pushed commit until both `CI` and `CodeQL` complete with `success`.

- [ ] **Step 7: Confirm final repository state**

```bash
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
```

Expected: the worktree is clean and both hashes are identical.

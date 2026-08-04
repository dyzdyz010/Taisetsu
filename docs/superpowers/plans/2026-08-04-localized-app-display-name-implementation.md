# Localized App Display Name Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show `重要日` below the main application icon for Simplified and Traditional Chinese while keeping `Taisetsu` for English, every other supported locale, and all technical identities.

**Architecture:** Keep `Taisetsu` as the base `CFBundleDisplayName` in the XcodeGen-owned Info.plist. Generate locale-specific InfoPlist String Catalog entries from the existing deterministic localization generator, and enforce the exact name matrix in the localization validation script.

**Tech Stack:** Xcode String Catalogs, Swift localization generator, Bash, jq, XcodeGen, GitHub Actions.

## Global Constraints

- `zh-Hans` and `zh-Hant` must resolve `CFBundleDisplayName` to `重要日`.
- English, `ja`, `ko`, `es`, `fr`, `de`, `pt-BR`, `it`, `ar`, and unsupported locales must display `Taisetsu`.
- `CFBundleName`, repository, project, target, module, bundle identifiers, App Group, CloudKit container, deep links, widget identity, and notification identifiers remain unchanged.
- Generated String Catalogs must contain no Xcode extraction-state drift.
- Work directly on `main`, create no pull request, and push only after local verification passes.

---

### Task 1: Add a failing display-name localization contract

**Files:**

- Modify: `scripts/localization-check.sh`
- Test: `scripts/localization-check.sh`

**Interfaces:**

- Consumes: `Taisetsu/Info.plist` and `Taisetsu/Resources/InfoPlist.xcstrings`.
- Produces: a nonzero exit when the base name or localized display-name matrix differs from the approved design.

- [ ] **Step 1: Add the exact display-name checks**

Append checks that keep the base name stable and validate all catalog values:

```bash
if [[ "$(plutil -extract CFBundleDisplayName raw Taisetsu/Info.plist)" != "Taisetsu" ]]; then
    echo "Base app display name must remain Taisetsu" >&2
    exit 1
fi

if ! jq -e '
    .strings.CFBundleDisplayName.localizations as $names
    | $names["zh-Hans"].stringUnit.value == "重要日"
      and $names["zh-Hant"].stringUnit.value == "重要日"
      and (["ja", "ko", "es", "fr", "de", "pt-BR", "it", "ar"]
        | map($names[.].stringUnit.value == "Taisetsu")
        | all)
' Taisetsu/Resources/InfoPlist.xcstrings >/dev/null; then
    echo "App display-name localization contract is invalid" >&2
    exit 1
fi
```

- [ ] **Step 2: Run the contract and verify RED**

Run: `bash scripts/localization-check.sh`

Expected: FAIL with `App display-name localization contract is invalid` because the deterministic InfoPlist catalog does not yet provide the two Chinese values and explicit non-Chinese values.

### Task 2: Generate the approved display-name matrix

**Files:**

- Modify: `scripts/generate-localizations.swift`
- Generate: `Taisetsu/Resources/InfoPlist.xcstrings`
- Normalize: `Taisetsu/Resources/Localizable.xcstrings`
- Normalize: `TaisetsuWidget/Resources/Localizable.xcstrings`

**Interfaces:**

- Consumes: the existing `Entry` locale order `zh-Hans`, `zh-Hant`, `ja`, `ko`, `es`, `fr`, `de`, `pt-BR`, `it`, `ar`.
- Produces: a deterministic `CFBundleDisplayName` catalog entry with Chinese `重要日` values and `Taisetsu` everywhere else.

- [ ] **Step 1: Add the display-name generator entry**

Insert this as the first `infoPlistEntries` value:

```swift
Entry(
    "CFBundleDisplayName", "重要日", "重要日", "Taisetsu", "Taisetsu", "Taisetsu", "Taisetsu",
    "Taisetsu", "Taisetsu", "Taisetsu", "Taisetsu"),
```

- [ ] **Step 2: Regenerate all catalogs**

Run: `swift scripts/generate-localizations.swift`

Expected: the generator prints `Localization catalogs generated.`; Xcode extraction metadata disappears; only the intentional InfoPlist name entry remains as a semantic catalog change.

- [ ] **Step 3: Run focused checks and verify GREEN**

Run:

```bash
swift scripts/generate-localizations.swift --check
bash scripts/localization-check.sh
```

Expected: catalog drift check passes and the localization script reports complete translations for ten translated locales.

- [ ] **Step 4: Review the generated diff**

Run:

```bash
git diff --check
git diff --stat
git diff -- Taisetsu/Resources/InfoPlist.xcstrings scripts/generate-localizations.swift scripts/localization-check.sh
```

Expected: the base Info.plist, `CFBundleName`, technical identifiers, app catalog, and widget catalog have no semantic changes.

### Task 3: Verify, commit, push, and monitor

**Files:**

- Verify all files modified by Tasks 1 and 2.

**Interfaces:**

- Consumes: the repository verification and GitHub Actions workflows.
- Produces: one verified implementation commit on `main` with a clean synchronized worktree.

- [ ] **Step 1: Run the complete local verification gate**

Run: `bash scripts/verify.sh`

Expected: project regeneration, naming checks, catalog checks, Swift formatting, app and widget builds, all unit tests, and coverage enforcement succeed.

- [ ] **Step 2: Commit the implementation**

```bash
git add scripts/generate-localizations.swift scripts/localization-check.sh \
    Taisetsu/Resources/InfoPlist.xcstrings
git commit -m "feat: localize app display name"
```

- [ ] **Step 3: Push directly to main**

Run: `git push origin main`

Expected: `origin/main` advances to the implementation commit without a pull request.

- [ ] **Step 4: Require remote verification**

Monitor the pushed commit until both `CI` and `CodeQL` complete with `success`.

- [ ] **Step 5: Confirm repository state**

Run:

```bash
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
```

Expected: the worktree is clean and both hashes are identical.

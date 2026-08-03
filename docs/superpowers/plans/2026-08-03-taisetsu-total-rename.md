# Taisetsu Total Technical Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every current-tree legacy product reference with the single public and technical identity `Taisetsu`, then rename the GitHub repository and local checkout.

**Architecture:** Treat `project.yml` as the authoritative project definition and perform tracked-path plus textual renames atomically so no pushed commit has mixed Swift modules or product identifiers. Add an executable naming gate that reconstructs forbidden aliases from split fragments, then run it locally and in CI before Xcode generation. Runtime identity is intentionally new; there is no compatibility reader for former storage, cloud, widget, notification, or URL identifiers.

**Tech Stack:** Swift 6, SwiftUI, WidgetKit, SwiftData, XcodeGen, Bash, Swift Testing, XCTest, Git, GitHub CLI, GitHub Actions

## Global Constraints

- Public and technical product name is exactly `Taisetsu`.
- Final targets are `Taisetsu`, `TaisetsuCore`, `TaisetsuWidget`, `TaisetsuTests`, and `TaisetsuUITests`.
- Bundle identifiers use `com.dyz.Taisetsu`; App Group uses `group.com.dyz.Taisetsu`; CloudKit uses `iCloud.com.dyz.Taisetsu`.
- Deep links use `taisetsu://`; notification identifiers use `taisetsu.`; automation variables use `TAISETSU_`.
- Current tracked paths and content must contain no forbidden legacy aliases.
- Git history is preserved and force-push is forbidden.
- The work is performed directly on `main` because the user explicitly selected that workflow.
- All eleven launch locales and small, medium, and large widget families remain supported.

---

### Task 1: Establish executable naming and runtime identity contracts

**Files:**
- Create: `scripts/naming-check.sh`
- Modify before path migration: legacy unit-test foundation file
- Modify before path migration: legacy widget-selection test file
- Modify before path migration: legacy core configuration file
- Modify before path migration: legacy widget snapshot file

**Interfaces:**
- Produces: `bash scripts/naming-check.sh`, an executable gate returning nonzero with path/content evidence when a forbidden alias exists.
- Produces: `AppConfiguration.appGroupIdentifier`, `cloudContainerIdentifier`, and `widgetKind` with Taisetsu values.
- Produces: `WidgetEventSnapshot.deepLink` using the `taisetsu` scheme.

- [ ] **Step 1: Create the naming gate before changing production names**

```bash
#!/bin/bash
set -euo pipefail

legacy_compound='Life''Timer'
legacy_lower='life''timer'
legacy_spaced='Life'' Timer'
legacy_chinese='生命''倒计时'
patterns=("${legacy_compound}" "${legacy_lower}" "${legacy_spaced}" "${legacy_chinese}")
failed=0

for pattern in "${patterns[@]}"; do
    path_matches=$(git ls-files | grep -iF "${pattern}" || true)
    content_matches=$(git grep -I -n -i -F "${pattern}" -- . || true)
    if [[ -n "${path_matches}" || -n "${content_matches}" ]]; then
        printf 'Forbidden legacy alias: %s\n' "${pattern}" >&2
        [[ -z "${path_matches}" ]] || printf '%s\n' "${path_matches}" >&2
        [[ -z "${content_matches}" ]] || printf '%s\n' "${content_matches}" >&2
        failed=1
    fi
done

exit "${failed}"
```

- [ ] **Step 2: Run the naming gate and verify RED**

Run: `bash scripts/naming-check.sh`

Expected: nonzero exit with legacy paths and content listed. The script itself must not appear in its own findings.

- [ ] **Step 3: Add failing consumer-facing runtime identity assertions**

Update the foundation test to assert these hand-derived literals:

```swift
#expect(AppConfiguration.appGroupIdentifier == "group.com.dyz.Taisetsu")
#expect(AppConfiguration.cloudContainerIdentifier == "iCloud.com.dyz.Taisetsu")
#expect(AppConfiguration.widgetKind == "TaisetsuUpcoming")
```

Add a widget snapshot assertion using a fixed UUID:

```swift
#expect(event.deepLink?.absoluteString == "taisetsu://anniversary/00000000-0000-4000-8000-000000000001")
```

- [ ] **Step 4: Run the focused tests and verify RED**

Run:

```bash
legacy='Life''Timer'
bash scripts/ci-test.sh \
  -only-testing:"${legacy}Tests/ProjectFoundationTests" \
  -only-testing:"${legacy}Tests/WidgetSelectionTests"
```

Expected: failures show the old runtime identifiers returned by real production code.

- [ ] **Step 5: Update only the runtime identifier values and verify GREEN**

Set the configuration values to `group.com.dyz.Taisetsu`, `iCloud.com.dyz.Taisetsu`, and `TaisetsuUpcoming`; set the deep-link scheme to `taisetsu`. Re-run the focused command and expect all selected tests to pass.

### Task 2: Atomically rename tracked paths, modules, targets, and generated project

**Files:**
- Rename to: `Taisetsu.xcodeproj/**`
- Rename to: `Taisetsu/**`
- Rename to: `TaisetsuCore/**`
- Rename to: `TaisetsuWidget/**`
- Rename to: `TaisetsuTests/**`
- Rename to: `TaisetsuUITests/**`
- Modify: `project.yml`
- Rename remaining tracked filenames containing forbidden aliases, including historic design and plan documents

**Interfaces:**
- Produces Swift modules: `Taisetsu`, `TaisetsuCore`, and `TaisetsuWidget`.
- Produces schemes: `Taisetsu`, `TaisetsuCore`, and `TaisetsuWidget`.
- Produces build products: `Taisetsu.app`, `TaisetsuCore.framework`, and `TaisetsuWidget.appex`.

- [ ] **Step 1: Rename every tracked path from a frozen file list**

```bash
legacy='Life''Timer'
legacy_lower='life''timer'
legacy_upper='LIFE''TIMER'
tracked_paths=$(mktemp)
git ls-files -z > "${tracked_paths}"
while IFS= read -r -d '' path; do
  new_path=${path//${legacy}/Taisetsu}
  new_path=${new_path//${legacy_lower}/taisetsu}
  new_path=${new_path//${legacy_upper}/TAISETSU}
  if [[ "${new_path}" != "${path}" ]]; then
    mkdir -p "$(dirname "${new_path}")"
    git mv "${path}" "${new_path}"
  fi
done < "${tracked_paths}"
```

- [ ] **Step 2: Mechanically replace exact legacy tokens in tracked text**

```bash
export LEGACY_COMPOUND='Life''Timer'
export LEGACY_LOWER='life''timer'
export LEGACY_UPPER='LIFE''TIMER'
export LEGACY_SPACED='Life'' Timer'
export LEGACY_CHINESE='生命''倒计时'
git grep -Il -z \
  -e "${LEGACY_COMPOUND}" -e "${LEGACY_LOWER}" -e "${LEGACY_UPPER}" \
  -e "${LEGACY_SPACED}" -e "${LEGACY_CHINESE}" -- . \
  | xargs -0 perl -pi -e '
      s/\Q$ENV{LEGACY_COMPOUND}\E/Taisetsu/g;
      s/\Q$ENV{LEGACY_LOWER}\E/taisetsu/g;
      s/\Q$ENV{LEGACY_UPPER}\E/TAISETSU/g;
      s/\Q$ENV{LEGACY_SPACED}\E/Taisetsu/g;
      s/\Q$ENV{LEGACY_CHINESE}\E/Taisetsu/g;
    '
```

- [ ] **Step 3: Review and correct semantic rename sites**

Ensure these renamed symbols and paths are internally consistent:

```text
Taisetsu/App/TaisetsuApp.swift             -> @main struct TaisetsuApp
TaisetsuWidget/TaisetsuWidgetBundle.swift  -> struct TaisetsuWidgetBundle
TaisetsuWidget/TaisetsuWidget.swift        -> widget configuration and kind
TaisetsuUITests/TaisetsuUITests.swift      -> final class TaisetsuUITests
project.yml                                -> all target, scheme, source, plist, entitlement, dependency, and bundle paths
```

Set the application, framework, widget, unit-test, and UI-test bundle identifiers to the exact Global Constraints values. Set entitlements to the new App Group and CloudKit identifiers.

- [ ] **Step 4: Regenerate the project and verify target discovery**

Run:

```bash
xcodegen generate
xcodebuild -list -project Taisetsu.xcodeproj
```

Expected: only Taisetsu-named targets and schemes appear; no obsolete scheme files remain.

- [ ] **Step 5: Run the focused tests through the renamed scheme**

Run:

```bash
bash scripts/ci-test.sh \
  -only-testing:TaisetsuTests/ProjectFoundationTests \
  -only-testing:TaisetsuTests/WidgetSelectionTests
```

Expected: all runtime identity and deep-link assertions pass.

### Task 3: Repair automation, documentation, and current-tree semantics

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/codeql.yml`
- Modify: `.github/ISSUE_TEMPLATE/bug.yml`
- Modify: `scripts/ci-test.sh`
- Modify: `scripts/coverage-check.sh`
- Modify: `scripts/verify.sh`
- Modify: `scripts/generate-localizations.swift`
- Modify: `scripts/localization-check.sh`
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`
- Modify: `LICENSE`
- Modify: `docs/brand-localization.md`
- Modify: all retained design and implementation documents

**Interfaces:**
- Consumes renamed target and path names from Task 2.
- Produces environment variables `TAISETSU_SIMULATOR_UDID`, `TAISETSU_INCLUDE_UI_TESTS`, and `TAISETSU_CORE_COVERAGE_MINIMUM`.
- Produces CI steps that run `scripts/naming-check.sh` before generation, build, or test.

- [ ] **Step 1: Update scripts and workflow commands to renamed paths and environment variables**

The canonical commands become:

```bash
xcodegen generate
xcrun swift-format lint --recursive Taisetsu TaisetsuCore TaisetsuWidget TaisetsuTests TaisetsuUITests
xcodebuild build -project Taisetsu.xcodeproj -scheme Taisetsu -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh
```

Update coverage lookup to `TaisetsuCore.framework`. Add `bash scripts/naming-check.sh` as the first content gate in `scripts/verify.sh`, the main CI job, the UI job, and CodeQL before build.

- [ ] **Step 2: Rewrite documentation around the single-identity model**

Remove the obsolete public-versus-technical compatibility discussion. Document the final repository, project, target, bundle, App Group, CloudKit, deep-link, and automation names. Preserve the product features, eleven locales, widget capacities, and testing instructions.

- [ ] **Step 3: Run deterministic generators and all static gates**

Run:

```bash
swift scripts/generate-localizations.swift
xcodegen generate
bash scripts/naming-check.sh
swift scripts/generate-localizations.swift --check
bash scripts/localization-check.sh
xcrun swift-format lint --recursive Taisetsu TaisetsuCore TaisetsuWidget TaisetsuTests TaisetsuUITests
git diff --check
```

Expected: every command succeeds and the naming gate prints no forbidden alias evidence.

### Task 4: Complete local verification and create the atomic rename commit

**Files:**
- Verify: all renamed source, tests, generated project, scripts, resources, and documentation

**Interfaces:**
- Consumes the fully renamed current tree.
- Produces one buildable atomic rename commit on `main` after the already committed design specification.

- [ ] **Step 1: Run the complete verification pipeline**

Run: `bash scripts/verify.sh`

Expected: naming, generated-file drift, localization, format, unsigned build, all unit tests, and at least 80% core coverage pass.

- [ ] **Step 2: Run the three UI smoke flows**

Run:

```bash
TAISETSU_INCLUDE_UI_TESTS=1 bash scripts/ci-test.sh \
  -only-testing:TaisetsuUITests/TaisetsuUITests/testCreatesAnAnniversaryFromTheEmptyState \
  -only-testing:TaisetsuUITests/TaisetsuUITests/testEditorUsesDateWheelsAndStructuredRecurrenceControls \
  -only-testing:TaisetsuUITests/TaisetsuUITests/testLaunchesWithEnglishLocalization
```

Expected: all three UI tests pass.

- [ ] **Step 3: Audit the complete staged diff**

Run:

```bash
git status --short --branch
git diff --check
bash scripts/naming-check.sh
git diff --stat
```

Confirm there are no unrelated changes, obsolete generated schemes, or unstaged files.

- [ ] **Step 4: Commit the atomic rename**

```bash
git add --all
git commit --no-gpg-sign -m "refactor: complete Taisetsu technical rename"
```

Expected: one rename-focused commit with Git detecting source/path moves where possible.

### Task 5: Rename GitHub repository, push, verify CI, and rename local checkout

**Files and external state:**
- Rename GitHub repository: `dyzdyz010/Taisetsu`
- Update remote: `https://github.com/dyzdyz010/Taisetsu.git`
- Rename local checkout: `/Users/dyz/Developer/playground/Taisetsu`

**Interfaces:**
- Consumes the verified atomic rename commit.
- Produces a clean `main` synchronized with the renamed GitHub repository.

- [ ] **Step 1: Rename the GitHub repository and update metadata**

```bash
current_repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
gh api --method PATCH "repos/${current_repo}" \
  -f name=Taisetsu \
  -f description='A local-first iOS app for important days, reminders, iCloud sync, and widgets.'
git remote set-url origin https://github.com/dyzdyz010/Taisetsu.git
```

- [ ] **Step 2: Verify protection and push directly to main**

Confirm administrator enforcement is disabled while required checks, linear history, force-push protection, and deletion protection remain configured. Fetch the renamed remote, confirm `main` is ahead only by the intended commits, then run `git push origin main`.

- [ ] **Step 3: Wait for GitHub CI and Swift CodeQL**

Use `gh run list` and `gh run watch --exit-status` for the pushed commit. Expected: main CI, UI smoke tests, coverage, localization/naming gates, and Swift CodeQL all conclude `success`.

- [ ] **Step 4: Rename the local checkout and perform the final audit**

From `/Users/dyz/Developer/playground`, rename the checkout directory to `Taisetsu`, continue with `workdir=/Users/dyz/Developer/playground/Taisetsu`, and run:

```bash
git fetch origin main
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
bash scripts/naming-check.sh
```

Expected: local and remote hashes match, branch is `main`, the worktree is clean, the new absolute path exists, and the naming gate passes.

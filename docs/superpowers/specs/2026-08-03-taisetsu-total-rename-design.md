# Taisetsu Total Technical Rename Design

**Date:** 2026-08-03

**Status:** Approved

## Objective

Give the product a single public and technical identity: **Taisetsu**. The repository's current tree, build configuration, generated project, source modules, runtime identifiers, automation, documentation, and GitHub repository must use the Taisetsu name exclusively.

The rename intentionally creates a new application identity. Existing development installs, local databases, private cloud records, widgets, notifications, and exported deep links are not migrated.

## Scope

The final structure uses these names:

| Role | Final name |
| --- | --- |
| GitHub repository | `dyzdyz010/Taisetsu` |
| Local repository directory | `/Users/dyz/Developer/playground/Taisetsu` |
| Xcode project and main scheme | `Taisetsu.xcodeproj`, `Taisetsu` |
| Application target and source module | `Taisetsu` |
| Domain framework | `TaisetsuCore` |
| Widget extension | `TaisetsuWidget` |
| Unit test bundle | `TaisetsuTests` |
| UI test bundle | `TaisetsuUITests` |
| Application bundle identifier | `com.dyz.Taisetsu` |
| Framework bundle identifier | `com.dyz.TaisetsuCore` |
| Widget bundle identifier | `com.dyz.Taisetsu.Widget` |
| Test bundle identifiers | `com.dyz.TaisetsuTests`, `com.dyz.TaisetsuUITests` |
| App Group | `group.com.dyz.Taisetsu` |
| CloudKit container | `iCloud.com.dyz.Taisetsu` |
| Deep-link scheme | `taisetsu` |
| Notification identifier prefix | `taisetsu.` |
| Script environment prefix | `TAISETSU_` |

Source filenames and Swift type names that include the product or target name follow the same mapping, including the application entry point, widget bundle, widget entry, widget view, and UI test classes.

## Current-tree cleanliness contract

The current repository tree must contain none of the former public name, former technical compound name, its spaced English form, or its former Chinese product label, with case-insensitive matching where applicable. This includes filenames, directory names, generated project content, source, tests, documentation, workflow files, issue templates, scripts, entitlements, and license text.

A naming validation script reconstructs the forbidden legacy aliases from split fragments at runtime. This keeps the validator capable of preventing regressions without preserving the forbidden aliases as literal repository content. CI runs this check before build and tests.

Git history is outside the current-tree cleanliness contract. Existing commits and their messages remain unchanged so commit hashes, previous Actions evidence, authorship, and audit history stay valid. No history rewrite or force-push is permitted.

## Project and runtime migration

The rename is atomic at the source level:

1. Rename tracked source, test, widget, entitlement, project, scheme, and historical design-document paths with Git-aware moves.
2. Update `project.yml` as the authoritative target, scheme, product, path, signing, bundle, App Group, and CloudKit configuration.
3. Update Swift module imports, application/widget types, runtime configuration, deep links, notification prefixes, snapshot filenames, tests, scripts, workflows, and documentation.
4. Regenerate the Xcode project from `project.yml`; do not hand-maintain stale generated references.
5. Run the forbidden-name scan across both tracked paths and tracked file content.

Because this is a new application identity, no code reads the former App Group, cloud container, database, widget snapshot, notification identifiers, or URL scheme. Simulator and unsigned CI builds remain self-contained. Signed device builds require the new identifiers and containers to exist for Apple Developer Team `98GGXKMU33`.

## Repository migration

After the renamed tree is committed and verified locally:

1. Rename the GitHub repository to `Taisetsu` through the GitHub API.
2. Set `origin` explicitly to `https://github.com/dyzdyz010/Taisetsu.git` rather than relying on GitHub's redirect.
3. Push the commit directly to `main` using the existing administrator bypass policy.
4. Verify branch protection still preserves required checks, linear history, disabled force pushes, and disabled deletions.
5. Rename the local repository directory only after all commands that reference the old workspace path have completed, then continue verification from the new absolute path.

## Validation and completion criteria

Completion requires all of the following:

- The naming validator reports no forbidden legacy path or content matches.
- XcodeGen reproduces the committed `Taisetsu.xcodeproj`, plists, and entitlements without drift.
- Localization generation and completeness checks still cover all eleven launch locales.
- Swift formatting passes for every renamed source and test directory.
- The application, framework, and widget build without signing.
- All unit tests pass and `TaisetsuCore` line coverage remains at least 80%.
- Simplified Chinese create flow, structured recurrence controls, and English brand launch UI tests pass.
- GitHub CI and Swift CodeQL complete successfully for the renamed repository.
- Local `HEAD` equals `origin/main`, the local directory is named `Taisetsu`, and the worktree is clean.

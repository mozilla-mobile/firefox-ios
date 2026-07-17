# Xcode Upgrade Checklist

Reference: https://xcodereleases.com/

This document walks through an Xcode version bump for the `firefox-ios` repo. Substitute `<XCODE_VERSION>` (e.g. `26.5`) and `<IOS_VERSION>` (e.g. `26.5`) below — they usually match but occasionally diverge while a simulator runtime catches up. Always confirm available runtimes with `xcrun simctl list runtimes`.

Work through Phase 1 (file edits) in order, then Phase 2 (verification). Stop and investigate any failures.

## Phase 1 — File edits

### 1. `README.md`

Update the Xcode badge URLs for both Firefox iOS and Focus iOS:

```diff
- <img src="https://img.shields.io/badge/Xcode-26.3-blue?...">
+ <img src="https://img.shields.io/badge/Xcode-<XCODE_VERSION>-blue?...">
```

- [ ] Firefox iOS badge updated
- [ ] Focus iOS badge updated

### 2. `.github/workflows/*.yml`

Update the `xcode:` matrix in every GitHub Actions workflow that pins Xcode:

- [ ] `firefox-ios-import-strings.yml`
- [ ] `firefox-ios-l10n-linter.yml`
- [ ] `firefox-ios-publish-docc.yml`
- [ ] `focus-ios-import-strings.yml`
- [ ] `focus-ios-l10n-linter.yml`
- [ ] `focus-ios-l10n-locales.yml`
- [ ] `focus-ios-l10n-screenshots.yml`

```diff
 strategy:
   matrix:
-    xcode: ["26.3"]
+    xcode: ["<XCODE_VERSION>"]
```

Sanity check: `grep -rn 'xcode:' .github/workflows/`

### 3. `bitrise.yml`

Several coordinated edits — search the file for the old version string and update every match.

- [ ] **Stack** — both occurrences of `stack: osx-xcode-<old>.x`. Prefer the stable stack (`osx-xcode-<XCODE_VERSION>.x`) over the edge stack (`osx-xcode-<XCODE_VERSION>.x-edge`) once available — the edge stack often produces flaky simulator behavior under parallel testing.

  ```diff
  - stack: osx-xcode-26.3.x
  + stack: osx-xcode-<XCODE_VERSION>.x
  ```

  Confirm the stack exists and inspect what it ships (Xcode version, iOS simulator runtimes, preinstalled tools) via the Bitrise stack report:

  - Stable: `https://bitrise.io/stacks/stack_reports/osx-xcode-<XCODE_VERSION>.x`
  - Edge: `https://bitrise.io/stacks/stack_reports/osx-xcode-<XCODE_VERSION>.x-edge`

  Use the report to verify the iOS simulator runtimes available — that determines the `<IOS_VERSION>` you use in `destination` and `xctestrun` paths below.

- [ ] **Simulator destinations** — every `destination: platform=iOS Simulator,name=...,OS=<old>`.

  ```diff
  - destination: platform=iOS Simulator,name=iPhone 17,OS=26.3
  + destination: platform=iOS Simulator,name=iPhone 17,OS=<IOS_VERSION>
  ```

- [ ] **`xctestrun` filenames** — Xcode embeds the iOS version into `.xctestrun` paths. Update every `iphonesimulator<old>` segment (UnitTest, Smoketest, AccessibilityTestPlan, plus `Firefox_*` and `FirefoxBeta_*` variants).

  ```diff
  - $BITRISE_TEST_BUNDLE_PATH/Fennec_UnitTest_iphonesimulator26.3-arm64.xctestrun
  + $BITRISE_TEST_BUNDLE_PATH/Fennec_UnitTest_iphonesimulator<IOS_VERSION>-arm64.xctestrun
  ```

- [ ] **Step titles** — any human-readable title mentioning the iOS version (e.g. `Unit Tests - iPhone 17 (iOS 26.2)`).

Sanity check: `grep -nE 'OS=26|iphonesimulator26|osx-xcode' bitrise.yml`

### 4. `firefox-ios/firefox-ios-tests/Tests/SyncIntegrationTests/xcodebuild.py`

```diff
- destination = 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1'
+ destination = 'platform=iOS Simulator,name=iPhone 17,OS=<IOS_VERSION>'
```

- [ ] Updated

### 5. `firefox-ios/l10n-screenshots.sh`

```diff
- --ios_version "26.3" \
+ --ios_version "<IOS_VERSION>" \
```

- [ ] Updated

## Phase 1b — Update Bitrise step dependencies

While you have `bitrise.yml` open, audit Bitrise step versions. Outdated or inconsistently-pinned steps occasionally have bugs that surface only on a new Xcode/iOS version.

- [ ] **Find every step reference.**

  ```bash
  grep -oE '^\s*-\s*[a-z][a-z0-9-]+@[0-9][0-9.]*' bitrise.yml | sed 's/^[[:space:]]*-[[:space:]]*//' | sort -u
  ```

- [ ] **Check each step's latest version** against the Bitrise step library:
  - Browse: https://www.bitrise.io/integrations/steps
  - Or query via the Bitrise MCP tool (`step_search`) if you have it configured.

- [ ] **Bump to latest stable for build/test-path steps**, in particular:
  - `xcode-build-for-test`
  - `xcode-test-without-building`
  - `xcode-test-shard-calculation`
  - `xcode-archive`
  - `activate-build-cache-for-xcode`
  - `restore-spm-cache` / `save-spm-cache`
  - `deploy-to-bitrise-io`

- [ ] **Resolve duplicate pinnings.** Same step referenced at multiple versions across workflows (e.g. `script@1.1` and `script@1.2.1`) is a smell — pick one and apply consistently.

- [ ] **Prefer major-only pins (`@N`) for stable, low-churn steps** so future patch fixes flow in automatically; pin to a specific version only when you need to lock behavior.

## Phase 2 — Verification

### Firefox iOS

- [ ] No compilation errors
- [ ] No new Swift errors or warnings
- [ ] No new test failures
  - [ ] Unit tests
  - [ ] Smoke tests
  - [ ] Full functional tests
  - [ ] L10n snapshot tests
  - [ ] Performance tests
  - [ ] Sync integration tests

### Focus iOS

- [ ] No compilation errors
- [ ] No new Swift errors or warnings
- [ ] No new test failures
  - [ ] Unit tests
  - [ ] Smoke tests
  - [ ] Full functional tests
  - [ ] L10n snapshot tests

### Bitrise

- [ ] Firefox Build workflow
- [ ] Firefox Unit tests
- [ ] Firefox Smoke tests
- [ ] Firefox Sync integration tests
- [ ] Focus Build workflow
- [ ] Focus Unit tests
- [ ] Focus Smoke tests
- [ ] Firefox L10n snapshot tests (`L10nBuild` workflow)

### Local sanity commands

```bash
xcodebuild build-for-testing -scheme Fennec \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=<IOS_VERSION>'

xcodebuild test -scheme Fennec -testPlan Smoketest \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=<IOS_VERSION>'
```

## Known gotchas

- **Edge vs stable Bitrise stack.** The `-edge` stack ships new Xcode versions first but its simulator runtimes are sometimes incomplete. If parallel UI tests hang during the test launch phase (build succeeds, sims boot, but no `Test Case` output ever appears), switch to the non-edge stack.
- **iOS version trailing Xcode version.** Apple sometimes ships e.g. Xcode 26.5 with an iOS 26.4.1 default simulator runtime. Check `xcrun simctl list runtimes` and pick the latest installed; the iOS version in destinations may lag by a patch.
- **SwiftLint pinning.** Past upgrades have required a `Pin swiftlint version` workaround step in `bitrise.yml`. Once the toolchain catches up, remove that workaround.
- **`Initialize CoreSimulator` warm-up steps.** Earlier upgrades added `xcrun simctl list` as a warm-up script before xcodebuild. These are usually safe to remove once the stack is stable.

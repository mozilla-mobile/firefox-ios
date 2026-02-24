# SwiftLint Configuration for Upstream Firefox Fork

* Status: accepted
* Deciders: Ecosia iOS Team
* Date: 2026-02-03
* Updated: 2026-02-10 (version pinning implementation)

## Context and Problem Statement

The Ecosia iOS browser is a fork of Mozilla's Firefox iOS browser. As a fork, we regularly merge upstream changes from Firefox to stay up-to-date with security patches, features, and improvements. This creates a challenge with linting: how do we maintain code quality in our codebase while avoiding conflicts when merging upstream changes?

## Decision Drivers

* Need to maintain code quality in Ecosia-specific code
* Need to minimize merge conflicts when incorporating Firefox upstream changes
* Want to use SwiftLint's `--fix` option for automatic code formatting
* Firefox core codebase has existing lint violations that are outside our control
* Need consistent SwiftLint version across team members and CI environment
* We want to maintain a zero-violation policy for most of the year
* We might have a time after the merge of upstream with violations

## Decision Outcome

### Implementation

This decision has been implemented using SwiftLint's baseline feature:

1. **Version Pinning**: SwiftLint is pinned to **version 0.63.2** across all environments:
   - Local development: `brew install swiftlint && brew pin swiftlint`
   - CI environment: Specified in [`.github/workflows/swift_lint.yml`](/.github/workflows/swift_lint.yml) using `ghcr.io/realm/swiftlint:0.63.2`
   - These versions must match to ensure consistent linting behavior

2. **Baseline Configuration**: A baseline file (`swiftlint_baseline.json`) captures all existing violations as of 2026-02-10:
   - Configured in `.swiftlint.yml`: `baseline: swiftlint_baseline.json`
   - SwiftLint only reports *new* violations not present in the baseline
   - This allows us to enforce standards on new code without fixing all historical violations

3. **Regenerating the Baseline**: When intentionally accepting new violations (e.g., after upstream merges):
   ```bash
   swiftlint --write-baseline swiftlint_baseline.json
   python3 -m json.tool --sort-keys swiftlint_baseline.json > swiftlint_baseline.tmp && mv swiftlint_baseline.tmp swiftlint_baseline.json
   ```

To ensure we can work with the file, the JSON is pretty printed and json-key-sorted

```shell
python3 -m json.tool --sort-keys swiftlint_baseline.json > swiftlint_baseline.tmp && mv swiftlint_baseline.tmp swiftlint_baseline.json
```

### Positive Consequences

* Merge conflicts with upstream Firefox are minimized
* New code must be lint-clean, preventing technical debt accumulation
* Ecosia-specific code can still benefit from `swiftlint --fix` automatic corrections
* Lint warnings in Firefox core files remain visible for awareness
* Easier to stay synchronized with Mozilla's upstream changes
* Consistent linting behavior across all developers and CI
* Baseline can be regenerated after major upstream merges to accept new Firefox violations

### Negative Consequences

* Firefox core files _could_ retain existing lint violations (but they're baselined)
* Baseline file requires manual regeneration after upstream merges
* Version pinning requires coordination when upgrading SwiftLint

## Pros and Cons of the Options

* Good, because it maintains visibility of all lint issues
* Good, because it minimizes merge conflicts with upstream
* Good, because Ecosia code can still be auto-fixed
* Bad, because there is currently no built-in SwiftLint mechanism to selectively apply `--fix`

## Implementation Details

### Version Consistency

**Upstream Firefox** enforces a strict zero violations policy on their main branch, which means their codebase is clean against their SwiftLint configuration. However, Firefox does not pin SwiftLint versions - they use whatever the latest version is at the time.

**Ecosia's approach** differs: we pin SwiftLint to ensure consistency across our team and CI:

* **Current Version**: 0.63.2 (selected at time of last upstream merge in Feb 2026)
* **Why we pin**: Unlike Firefox, we need consistent linting behavior across all developers and CI runs to avoid "works on my machine" issues with different SwiftLint versions

When performing Firefox upstream merges, we evaluate whether to update our pinned SwiftLint version:

* **Upgrade Process**:
  1. During upstream merge, assume Firefox is using the latest stable SwiftLint available at that time
  2. Consider upgrading to that version (or latest stable) to align with Firefox's codebase expectations
  3. Update both CI and local development instructions with the new version
  4. Regenerate the baseline with the new version to capture any new rule behavior

To ensure consistent linting results across environments:

* **CI**: Version is specified in `.github/workflows/swift_lint.yml` (line 9): `image: ghcr.io/realm/swiftlint:0.63.2`
* **Local**: Developers pin the version using Homebrew: `brew pin swiftlint`
* **Documentation**: Setup instructions in `firefox-ios/Ecosia/Ecosia.docc/Ecosia.md`

This pinning strategy ensures that violations introduced by Firefox upstream are minimal (since Mozilla maintains zero violations), while giving us predictable, consistent linting behavior across the team.

### Baseline Workflow

1. **Normal Development**: Developers only see lint violations in code they've added or modified
2. **After Upstream Merge**: If Firefox introduces new violations:
   - Review the violations to ensure they're from upstream (not our changes)
   - Regenerate the baseline to accept Firefox's violations
   - Commit the updated `swiftlint_baseline.json`
3. **Version Upgrades**: When upgrading SwiftLint:
   - Update the version in `.github/workflows/swift_lint.yml`
   - Update local installations: `brew unpin swiftlint && brew upgrade swiftlint && brew pin swiftlint`
   - Regenerate the baseline (new versions may detect different violations)
   - Update documentation in `firefox-ios/Ecosia/Ecosia.docc/Ecosia.md`

## Resolved Issues

* By pinning the version of swiftlint we introduce some consistency
* the baseline offers an option to *temporarely* ignore swiftlint issues


for some reason running `swiftlint --fix firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift` for instance would not work out of the box:
```
➜ swiftlint  firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift 
\warning: 'redundant_optional_initialization' has been renamed to 'implicit_optional_initialization' and will be completely removed in a future release.
warning: 'operator_whitespace' has been renamed to 'function_name_whitespace' and will be completely removed in a future release.
warning: Found a configuration for 'line_length' rule, but it is not present in 'only_rules'.
Linting Swift files at paths firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift
Linting 'AppSettingsTableViewController+Ecosia.swift' (1/1)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:143:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:144:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:146:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:147:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
/Users/falkorichter/Documents/ios-browser-2026/firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift:148:25: warning: Vertical Parameter Alignment on Call Violation: Function parameters should be aligned vertically if they're in multiple lines in a method call (vertical_parameter_alignment_on_call)
Done linting! Found 5 violations, 0 serious in 1 file.

➜ swiftlint --fix firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift
warning: 'redundant_optional_initialization' has been renamed to 'implicit_optional_initialization' and will be completely removed in a future release.
warning: 'operator_whitespace' has been renamed to 'function_name_whitespace' and will be completely removed in a future release.
warning: Found a configuration for 'line_length' rule, but it is not present in 'only_rules'.
Correcting Swift files at paths firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift
Correcting 'AppSettingsTableViewController+Ecosia.swift' (1/1)
Done correcting 1 file!
```
It mentions `Done correcting 1 file!` but the file has not been fixed and had to be fixed manually.

## Links

* [SwiftLint Configuration](../../.swiftlint.yml) - Current SwiftLint rules and exclusions
* [SwiftLint Baseline](../../swiftlint_baseline.json) - Baseline file capturing existing violations
* [SwiftLint CI Workflow](../../.github/workflows/swift_lint.yml) - GitHub Actions workflow with version specification
* [Ecosia README - SwiftLint Section](../../firefox-ios/Ecosia/Ecosia.docc/Ecosia.md) - Setup instructions for developers
* [Firefox iOS Repository](https://github.com/mozilla-mobile/firefox-ios) - Upstream repository

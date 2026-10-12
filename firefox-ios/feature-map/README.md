# Feature map

Attributes Firefox iOS source code to product features so test coverage can be reported per feature.
The feature IDs come from the cross-platform Firefox feature taxonomy, so iOS numbers line up with Android and desktop.

| File | Purpose |
|---|---|
| `features.yml` | Feature IDs, plus `SHARED.*` buckets for code that serves many features and `EXCLUDED` for code that isn't counted |
| `feature-map.yml` | Rules that attribute each Swift file, or individual functions in large files, to one ID |
| `feature_map.py` | Resolves the rules and produces reports |

## Commands

Run from the repository root. [`uv`](https://docs.astral.sh/uv/) installs PyYAML automatically.

```bash
uv run firefox-ios/feature-map/feature_map.py check      # every file resolves, no ambiguous or dead rules
uv run firefox-ios/feature-map/feature_map.py files      # CSV: the feature and matching rule for each file
uv run firefox-ios/feature-map/feature_map.py lines      # CSV: files and source lines per feature

xcrun xccov view --report --json Test.xcresult > coverage.json
uv run firefox-ios/feature-map/feature_map.py coverage coverage.json   # CSV: covered/executable lines per feature, plus code the run did not measure
```

The `xccov` report leaves out some Swift packages. Xcode looks for their coverage in a different binary from the one that ran. Affected packages include `Common`, `Redux` and `QuickAnswersKit`. To fill those gaps, pass the run's profile data and the instrumented binaries. For any file missing from the report, line counts are then read directly with `llvm-cov`:

```bash
DD=~/Library/Developer/Xcode/DerivedData/Client-<hash>
P=$DD/Build/Products/Debug-iphonesimulator
uv run firefox-ios/feature-map/feature_map.py coverage coverage.json \
  --profdata "$(ls -t $DD/Build/ProfileData/*/Coverage.profdata | head -1)" \
  --binary "$P/Client.app/Client.debug.dylib" \
  --binary "$P/PackageFrameworks/Common.framework/Common" \
  --binary "$P/PackageFrameworks/Redux.framework/Redux"
```

## How rules resolve

- **The most specific rule wins, and rule order doesn't matter.** An exact file path beats a glob. Among globs, the one with more literal path segments wins, then the longer pattern. Two equally specific rules matching one file is an error.
- **Folder rules don't need to cover every file.** If a new file matches no rule, `check` fails, so someone has to decide where it belongs.
- **`symbols` split one file across features.** Each entry is a regex matched against function names from `xccov`. Closures count toward the function they're inside, and functions that match no entry use the file's `feature`. Symbol rules only affect the `coverage` command.

```yaml
- path: "firefox-ios/Client/Frontend/Browser/BrowserViewController/Views/BrowserViewController.swift"
  feature: SHARED.SHELL
  symbols:
    - {match: "(?i)readerMode", feature: BRW.READ}
```

## Choosing a feature

- **Ask which feature breaks if this code breaks.** A settings row belongs to the feature it configures. For example, `AddressAutofillSetting.swift` is `CRED.ADDR`, not `SET.FRAME`.
- **Telemetry for one feature goes with that feature.** `SHARED.TELEMETRY` is only for telemetry infrastructure.
- **Use a `SHARED.*` bucket only when the code genuinely serves many features.** These buckets are reported separately, so the amount of shared code stays visible.

## Review status

Rules marked `by: ai` were generated and haven't been checked yet. Delete the marker once you've reviewed a rule. `check` reports how many rules are still waiting for review.

# Contributing — Ecosia iOS

Quick essentials for contributors.

Git hooks

After cloning, install the repository hooks:

```bash
./setup_hooks.sh
```

Commenting Ecosia modifications

When you modify upstream Firefox code or add Ecosia-specific logic, use clear comment prefixes so downstream rebases are easier.

One-liner example:

```swift
// Ecosia: Update appversion predicate
let appVersionPredicate = (appVersionString?.contains("Ecosia") ?? false) == true
```

Block comment example (commenting out upstream code for clarity):

```swift
/* Ecosia: Update appversion predicate
let appVersionPredicate = (appVersionString?.contains("Firefox") ?? false) == true
*/
let appVersionPredicate = (appVersionString?.contains("Ecosia") ?? false) == true
```

Linting

- We use SwiftLint. New code should be lint-clean.
- CI pins a SwiftLint version; during upgrades we may temporarily use a baseline for Ecosia files only, but main must be clean.

Pull request guidance

- Keep PRs focused and small.
- When changing upstream files, explain why the change is scoped to Ecosia and include references to upstream files to ease rebasing.

If you want a contributor checklist (tests, snapshots, lint, CI), tell me and I will add it here.
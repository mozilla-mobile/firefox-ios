---
name: bootstrap
description: Setup both Firefox and Focus for iOS after fetching from git.
allowed-tools: Bash(brew *) Bash(which *)
---

First, check if `fxios` is installed:

```
which fxios
```

If it is not installed, run:

```
brew tap mozilla-mobile/fxios
brew install fxios
```

If it is installed, upgrade to the latest version:

```
brew upgrade fxios
```

Then run these steps in sequence from the root of the firefox-ios repository:

1. `fxios --version`
2. `fxios bootstrap --all`

Stop and report if any step fails.
#!/usr/bin/env python3
"""Ecosia: fail the build when a checked-in Package.resolved disagrees with an exact: pin.

PR #1218 moved sentry-cocoa to `exact: "9.10.0"` and updated two sibling lockfiles but missed
`firefox-ios/Client.xcodeproj/…/swiftpm/Package.resolved` — the only one the CI build reads, and
the sole input to the SPM cache key. It stayed on 8.36.0 for days. That file is tracked but sits
under a gitignored directory, so it never shows up in review and needs `git add -f`.

Only `exact:` requirements are checked, and only against lockfiles that already pin the package.
`.branch(...)` and version-range dependencies legitimately move when upstream does, so asserting
on those (or re-resolving and diffing) would turn CI red on unrelated PRs.

Usage: check_pinned_dependencies.py [repo_root]

Exits 1 on any mismatch or on conflicting exact requirements for the same package.

Runs before actions/setup-python so it executes under the runner's system Python. Keep it to the
standard library and avoid version-specific APIs (no str.removesuffix, no match statements), or it
will fail before the pinned Python is installed.
"""

import json
import os
import re
import sys

# Manifests that declare exact pins. Both must agree with each other and with every lockfile.
MANIFESTS = [
    "BrowserKit/Package.swift",
    "firefox-ios/Tuist/ProjectDescriptionHelpers/Packages+Ecosia.swift",
]

# Checked-in lockfiles for the firefox-ios/BrowserKit graph. focus-ios is excluded: it has its
# own manifests and is not built by this CI, so asserting our pins against it would be wrong.
LOCKFILES = [
    "firefox-ios/Client.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "firefox-ios/Client.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "firefox-ios/.package.resolved",
    "BrowserKit/Package.resolved",
    "MozillaRustComponents/Package.resolved",
]

# `url: "…", exact: "…"` (Package.swift) and `.remote(url: "…", requirement: .exact("…"))` (Tuist).
EXACT_PATTERNS = [
    re.compile(r'url:\s*"([^"]+)"\s*,\s*exact:\s*"([^"]+)"', re.S),
    re.compile(r'url:\s*"([^"]+)"\s*,\s*requirement:\s*\.exact\(\s*"([^"]+)"\s*\)', re.S),
]


def identity(url):
    """SwiftPM's package identity: the last URL path component, lowercased, without `.git`.

    Strips any embedded credentials first, since CI rewrites Ecosia-owned URLs to include an access
    token before the build and that must not change the derived identity.
    """
    url = re.sub(r"//[^/@]*@", "//", url)
    name = os.path.basename(url.rstrip("/"))
    if name.endswith(".git"):
        name = name[: -len(".git")]
    return name.lower()


def exact_requirements(root):
    """Map package identity -> {version: [manifests declaring it]} for every exact: pin."""
    found = {}
    for relative in MANIFESTS:
        path = os.path.join(root, relative)
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as handle:
            source = handle.read()
        for pattern in EXACT_PATTERNS:
            for url, version in pattern.findall(source):
                found.setdefault(identity(url), {}).setdefault(version, []).append(relative)
    return found


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    required = exact_requirements(root)

    if not required:
        sys.exit("check_pinned_dependencies: found no exact: pins — the parser is probably broken")

    problems = []

    # A package pinned to two different exact versions across manifests can never resolve cleanly.
    for package, versions in sorted(required.items()):
        if len(versions) > 1:
            detail = "; ".join(
                f"{version} in {', '.join(sorted(set(files)))}" for version, files in sorted(versions.items())
            )
            problems.append(f"{package}: manifests disagree on the exact version — {detail}")

    print(f"Verifying {len(required)} exact-pinned dependencies against checked-in lockfiles.\n")

    for relative in LOCKFILES:
        path = os.path.join(root, relative)
        if not os.path.isfile(path):
            print(f"{relative}: absent, skipped")
            continue

        try:
            with open(path, encoding="utf-8") as handle:
                pins = {pin["identity"]: pin for pin in json.load(handle).get("pins", [])}
        except (json.JSONDecodeError, KeyError, TypeError) as error:
            # A truncated or rewritten lockfile is itself a problem worth failing on, but report it
            # as one line rather than a traceback.
            print(f"  UNREADABLE {relative}: {error}")
            problems.append(f"{relative}: not valid Package.resolved JSON ({error})")
            continue

        mismatches = []
        for package, versions in sorted(required.items()):
            pin = pins.get(package)
            if pin is None:
                continue  # This lockfile's graph does not include the package. Not our business.
            resolved = pin.get("state", {}).get("version")
            expected = sorted(versions)
            if resolved not in expected:
                mismatches.append((package, "/".join(expected), resolved))

        if mismatches:
            for package, expected, resolved in mismatches:
                print(f"  MISMATCH {package}: manifests require {expected}, lockfile pins {resolved}")
                problems.append(f"{relative}: {package} pinned at {resolved}, manifests require {expected}")
        else:
            print(f"{relative}: OK")

    if not problems:
        print("\nAll exact-pinned dependencies agree with every checked-in lockfile.")
        return

    print("\nFAILED: checked-in lockfiles disagree with the manifests.\n")
    for problem in problems:
        print(f"  - {problem}")
    print(
        "\nTo fix: let Xcode re-resolve (or run"
        " `xcodebuild -resolvePackageDependencies -project firefox-ios/Client.xcodeproj`)"
        " and commit every changed Package.resolved. Note the Client.xcodeproj one is tracked but"
        " sits under a gitignored path, so `git add` needs -f and `git status` will not nag you"
        " about it."
    )
    sys.exit(1)


if __name__ == "__main__":
    main()

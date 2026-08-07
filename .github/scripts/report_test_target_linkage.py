#!/usr/bin/env python3
"""Ecosia: check which SPM package products each test bundle actually links.

Xcode leaves dynamic package products off an app-hosted `.xctest` bundle's link line even when the
project declares them correctly, relying on `ld` to resolve them through the test host. That works
locally but not on CI. See TestTargets.appHostedTestSettings for the explanation and the fix.

Since `xcodebuild` stops at the first failing target, a run would otherwise reveal only one
affected target at a time. This compares each test target's declared package products against the
frameworks actually on its `Ld` command, so one run lists everything at risk.

Usage: report_test_target_linkage.py <raw_build_log> <project.pbxproj>

Exits 1 if an app-hosted target is not deferring symbol resolution, or if a target that should
link its package products directly is missing one.
"""

import json
import os
import re
import subprocess
import sys

LD_LINE_RE = re.compile(r"Ld \S+\.xctest/\w+ normal .*in target '(\w+)'")


def declared_package_products(pbxproj_path):
    """Map target name -> package product names declared in the generated project.

    A `.pbxproj` is an OpenStep property list, so `plutil` reads it properly. Scraping it with
    regexes instead is unreliable: Xcode rewrites the file's formatting whenever the project is
    opened, which silently changes what a hand-rolled parser can see.
    """
    converted = subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", pbxproj_path],
        capture_output=True,
        check=True,
        text=True,
    )
    objects = json.loads(converted.stdout)["objects"]

    declared = {}
    for obj in objects.values():
        if obj.get("isa") != "PBXNativeTarget":
            continue
        products = [
            objects.get(ref, {}).get("productName")
            for ref in obj.get("packageProductDependencies", [])
        ]
        declared[obj["name"]] = sorted(name for name in products if name)
    return declared


def link_commands(log_path):
    """Map test target name -> the clang link command line from its `Ld` task."""
    with open(log_path, encoding="utf-8", errors="replace") as handle:
        lines = handle.read().splitlines()

    commands = {}
    for index, line in enumerate(lines):
        match = LD_LINE_RE.match(line)
        if not match:
            continue
        # The task header is followed by `cd`/`export` lines before the actual invocation.
        for candidate in lines[index + 1:index + 12]:
            if "/clang" in candidate and " -o " in candidate:
                commands[match.group(1)] = candidate
                break
    return commands


def linkage(command):
    """Extract (dynamic framework names, statically linked package module names) from a link line."""
    tokens = command.split()

    frameworks = {
        tokens[i + 1]
        for i, token in enumerate(tokens)
        if token == "-framework" and i + 1 < len(tokens)
    }
    # Xcode links package products by absolute path rather than by -framework.
    frameworks |= {
        os.path.basename(token).split(".framework")[0]
        for token in tokens
        if "PackageFrameworks/" in token
    }
    # Statically linked package targets arrive via per-module linker response files instead.
    static = {
        os.path.basename(token)[: -len("-linker-args.resp")]
        for token in tokens
        if token.endswith("-linker-args.resp")
    }
    return sorted(frameworks), static


def classify(product, frameworks, static):
    """How a declared package product is accounted for on the link line, if at all."""
    hashed = f"{product}_"
    if product in frameworks or any(
        name.startswith(hashed) and name.endswith("_PackageProduct") for name in frameworks
    ):
        return "dynamic"
    if product in static:
        return "static"
    return None


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    log_path, pbxproj_path = sys.argv[1], sys.argv[2]

    # Runs as an `if: always()` CI step, so a missing input must not fail the step on top of
    # whatever already went wrong.
    for path in (log_path, pbxproj_path):
        if not os.path.isfile(path):
            print(f"skipping report: {path} not found")
            return

    declared = declared_package_products(pbxproj_path)
    commands = link_commands(log_path)

    test_targets = sorted(name for name in declared if name.endswith("Tests"))
    unaccounted = {}
    unguarded = []
    unexpected = {}

    for target in test_targets:
        products = declared[target]
        command = commands.get(target)

        print(f"=== {target} ===")
        if command is None:
            print("    not linked in this run (build stopped before reaching it)")
            print()
            continue

        frameworks, static = linkage(command)
        # `-bundle_loader` is what makes a test bundle app-hosted, and app-hosting is exactly the
        # condition under which Xcode drops dynamic package products from the link line.
        hosted = "-bundle_loader" in command
        deferred = "dynamic_lookup" in command
        print(f"    app-hosted: {'yes' if hosted else 'no'}")
        print(f"    dynamic_lookup: {'yes' if deferred else 'no'}")
        print(f"    frameworks on link line: {', '.join(frameworks) or '(none)'}")

        if not products:
            print("    declares no package products")
            print()
            continue

        missing = []
        for product in products:
            how = classify(product, frameworks, static)
            print(f"    {product}: {how or 'NOT LINKED'}")
            if how is None:
                missing.append(product)

        if missing:
            unaccounted[target] = (hosted, missing)

        # Relying on `ld` to reach these through the host works in some environments and not others,
        # so flag it now rather than waiting for it to fail somewhere else.
        if hosted and not deferred:
            unguarded.append(target)

        # Non-app-hosted targets link their package products normally, so a gap here means the
        # assumption behind the whole workaround no longer holds.
        if not hosted and missing:
            unexpected[target] = missing

        print()

    print("=== summary ===")

    if unaccounted:
        print("Declared package products missing from the link line:")
        for target, (hosted, products) in sorted(unaccounted.items()):
            marker = "app-hosted" if hosted else "NOT app-hosted"
            print(f"  {target} ({marker}): {', '.join(products)}")
        print()
        print("Expected on app-hosted targets: appHostedTestSettings defers these to load time.")
        print("What matters there is that the bundle links and its tests load.")
        print()

    if not unguarded and not unexpected:
        print("PASS: app-hosted targets defer symbol resolution; all others link their products.")
        return

    print("FAIL")

    if unguarded:
        print()
        print("App-hosted, but not passing -undefined dynamic_lookup, so they depend on ld")
        print("resolving package symbols through the Client host. That is environment-dependent:")
        print("it may link here and fail on another machine or toolchain.")
        for target in sorted(unguarded):
            print(f"  {target}")
        print()
        print("Fix: base their settings on TestTargets.appHostedTestSettings in Targets+Tests.swift.")

    if unexpected:
        print()
        print("Not app-hosted, so Xcode should be linking these directly. A gap here means the")
        print("assumption behind appHostedTestSettings no longer holds — investigate, do not paper over:")
        for target, products in sorted(unexpected.items()):
            print(f"  {target}: {', '.join(products)}")

    sys.exit(1)


if __name__ == "__main__":
    main()

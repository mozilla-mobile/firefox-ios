#!/usr/bin/env python3
"""List the XCUITests tagged with `// Regression`.

The tag is looked up in the contiguous comment block right above the
`func testXxx` declaration, which is where this repo's convention puts it:

    // https://mozilla.testrail.io/index.php?/cases/view/2306922
    // Regression
    func testSomething() {

The result is cross-checked against the given test plan's `skippedTests`,
because `-only-testing` does NOT override a plan skip: a test that is both
requested and skipped simply never runs, and the job still goes green.
"""

import argparse
import json
import os
import re
import sys

CLASS_RE = re.compile(r"^\s*(?:public\s+|final\s+)*class\s+(\w+)\s*:\s*(\w+)")
FUNC_RE = re.compile(r"^\s*func\s+(test\w*)\s*\(")
LABEL_RE = re.compile(r"^//\s*(Regression|Smoketest)\b", re.IGNORECASE)

TARGET = "XCUITests"

# Files launched through a different pipeline, out of scope for this job.
DEFAULT_EXCLUDED_FILES = ["IntegrationTests.swift"]


def parse_tests(root, excluded_files):
    """Return [{class, func, base, label, file, line}] for the whole tree."""
    tests = []
    for dirpath, _, filenames in os.walk(root):
        for filename in sorted(filenames):
            if not filename.endswith(".swift") or filename in excluded_files:
                continue
            path = os.path.join(dirpath, filename)
            with open(path, encoding="utf-8") as handle:
                lines = handle.read().split("\n")
            current_class = current_base = None
            for index, line in enumerate(lines):
                class_match = CLASS_RE.match(line)
                if class_match:
                    current_class, current_base = class_match.group(1), class_match.group(2)
                func_match = FUNC_RE.match(line)
                if not func_match or not current_class:
                    continue
                label = None
                cursor = index - 1
                while cursor >= 0 and lines[cursor].strip().startswith("//"):
                    label_match = LABEL_RE.match(lines[cursor].strip())
                    if label_match and label is None:
                        label = label_match.group(1).capitalize()
                    cursor -= 1
                tests.append({
                    "class": current_class,
                    "func": func_match.group(1),
                    "base": current_base,
                    "label": label,
                    "file": path,
                    "line": index + 1,
                })
    return tests


def plan_skips(plan_path):
    """(whole classes skipped, individual methods skipped) from the test plan."""
    if not plan_path or not os.path.exists(plan_path):
        return set(), set()
    with open(plan_path, encoding="utf-8") as handle:
        plan = json.load(handle)
    skipped = set()
    for target in plan.get("testTargets", []):
        skipped |= set(target.get("skippedTests", []))
    classes = {entry for entry in skipped if "/" not in entry}
    methods = {entry.replace("()", "") for entry in skipped if "/" in entry}
    return classes, methods


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default=os.path.dirname(here),
                        help="XCUITests directory (defaults to the script's own)")
    parser.add_argument("--plan", default=os.path.join(os.path.dirname(os.path.dirname(here)),
                                                       "FullFunctionalTestPlan.xctestplan"),
                        help="Test plan whose skippedTests are cross-checked")
    parser.add_argument("--format", choices=["plain", "only-testing", "json"], default="plain")
    parser.add_argument("--shard", metavar="I/N",
                        help="Split the list into N chunks and emit chunk I (1-based)")
    parser.add_argument("--include-plan-skipped", action="store_true",
                        help="Keep the plan-skipped ones (emitted even though they will not run)")
    parser.add_argument("--exclude-file", action="append", default=[], metavar="NAME.swift",
                        help="File to ignore, on top of the default exclusions ({})".format(
                            ", ".join(DEFAULT_EXCLUDED_FILES)))
    parser.add_argument("--no-default-excludes", action="store_true",
                        help="Do not apply the default exclusion list")
    args = parser.parse_args()

    excluded_files = set(args.exclude_file)
    if not args.no_default_excludes:
        excluded_files |= set(DEFAULT_EXCLUDED_FILES)
    if excluded_files:
        print("Excluded files: {}".format(", ".join(sorted(excluded_files))), file=sys.stderr)

    tests = parse_tests(args.root, excluded_files)
    regression = [t for t in tests if t["label"] == "Regression"]
    skipped_classes, skipped_methods = plan_skips(args.plan)

    runnable, blocked = [], []
    for test in regression:
        identifier = "{}/{}".format(test["class"], test["func"])
        if test["class"] in skipped_classes or identifier in skipped_methods:
            blocked.append(test)
            if args.include_plan_skipped:
                runnable.append(test)
        else:
            runnable.append(test)

    runnable.sort(key=lambda t: (t["class"], t["func"]))

    if args.shard:
        index, total = (int(part) for part in args.shard.split("/"))
        runnable = runnable[index - 1::total]

    print("{} tests tagged // Regression, {} runnable under this plan".format(
        len(regression), len(runnable)), file=sys.stderr)
    if blocked:
        print("WARNING: {} test(s) tagged // Regression are in the skippedTests of {} and will "
              "NOT run (-only-testing does not override a plan skip):".format(
                  len(blocked), os.path.basename(args.plan)), file=sys.stderr)
        for test in sorted(blocked, key=lambda t: (t["class"], t["func"])):
            print("  - {}/{}  ({}:{})".format(test["class"], test["func"],
                                              test["file"], test["line"]), file=sys.stderr)

    if args.format == "json":
        print(json.dumps({
            "regression": len(regression),
            "excludedFiles": sorted(excluded_files),
            "runnable": [{"id": "{}/{}".format(t["class"], t["func"]), **t} for t in runnable],
            "blockedByPlan": ["{}/{}".format(t["class"], t["func"]) for t in blocked],
        }, indent=2))
    elif args.format == "only-testing":
        for test in runnable:
            print("-only-testing:{}/{}/{}".format(TARGET, test["class"], test["func"]))
    else:
        for test in runnable:
            print("{}/{}/{}".format(TARGET, test["class"], test["func"]))

    return 0


if __name__ == "__main__":
    sys.exit(main())

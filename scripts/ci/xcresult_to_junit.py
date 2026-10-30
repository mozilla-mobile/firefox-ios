#!/usr/bin/env python3
"""Convert an .xcresult into JUnit XML (Jenkins junit plugin) + markdown summary."""

import argparse
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

DURATION_RE = re.compile(r"(?:(\d+)m)?\s*([\d.,]+)s")


class UnreadableBundle(Exception):
    """The .xcresult cannot be read: usually the run never started."""


def xcresulttool(subcommand, path):
    result = subprocess.run(
        ["xcrun", "xcresulttool", "get", "test-results", subcommand,
         "--path", path, "--format", "json", "--compact"],
        capture_output=True, text=True)
    if result.returncode != 0:
        raise UnreadableBundle("xcresulttool exited with {}: {}".format(
            result.returncode, result.stderr.strip().split("\n")[0]))
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise UnreadableBundle("unreadable xcresulttool output: {}".format(error))


def parse_duration(value):
    if not value:
        return 0.0
    match = DURATION_RE.search(value.replace(",", "."))
    if not match:
        return 0.0
    minutes = float(match.group(1) or 0)
    return minutes * 60 + float(match.group(2))


def collect_cases(nodes, suite=None, out=None):
    """Walk the testNodes tree and return the Test Case nodes."""
    out = [] if out is None else out
    for node in nodes or []:
        node_type = node.get("nodeType")
        if node_type == "Test Suite":
            suite = node.get("name", suite)
        if node_type == "Test Case":
            failures, repetitions = [], 0
            for child in node.get("children", []):
                child_type = child.get("nodeType")
                if child_type in ("Failure Message", "Expected Failure"):
                    failures.append(child.get("name", ""))
                elif child_type == "Repetition":
                    repetitions += 1
                    for grandchild in child.get("children", []):
                        if grandchild.get("nodeType") == "Failure Message":
                            failures.append(grandchild.get("name", ""))
            out.append({
                "suite": suite or "XCUITests",
                "name": node.get("name", "?"),
                "result": node.get("result", "Unknown"),
                "duration": parse_duration(node.get("duration")),
                # under retryOnFailure the same message shows up once per repetition
                "failures": list(dict.fromkeys(failures)),
                "repetitions": repetitions,
            })
            continue
        collect_cases(node.get("children"), suite, out)
    return out


def build_junit(cases, suite_name):
    by_suite = {}
    for case in cases:
        by_suite.setdefault(case["suite"], []).append(case)

    root = ET.Element("testsuites", name=suite_name)
    for suite, suite_cases in sorted(by_suite.items()):
        failed = sum(1 for c in suite_cases if c["result"] == "Failed")
        skipped = sum(1 for c in suite_cases if c["result"] == "Skipped")
        element = ET.SubElement(root, "testsuite", name=suite,
                                tests=str(len(suite_cases)),
                                failures=str(failed), skipped=str(skipped), errors="0",
                                time="{:.3f}".format(sum(c["duration"] for c in suite_cases)))
        for case in suite_cases:
            case_element = ET.SubElement(element, "testcase", classname=suite,
                                         name=case["name"],
                                         time="{:.3f}".format(case["duration"]))
            if case["result"] == "Failed":
                failure = ET.SubElement(case_element, "failure",
                                        message=(case["failures"][0] if case["failures"]
                                                 else "Test failed")[:400])
                failure.text = "\n".join(case["failures"])
            elif case["result"] == "Skipped":
                ET.SubElement(case_element, "skipped")
    return ET.ElementTree(root)


def write_summary(path, cases, blocked, excluded_files, xcresult):
    totals = {}
    for case in cases:
        totals[case["result"]] = totals.get(case["result"], 0) + 1
    failed = sorted((c for c in cases if c["result"] == "Failed"),
                    key=lambda c: (c["suite"], c["name"]))
    lines = [
        "# XCUITest — Regression run",
        "",
        "Bundle: `{}`".format(os.path.basename(xcresult)),
        "",
        "| Result | Count |",
        "|---|---|",
    ]
    for key in sorted(totals):
        lines.append("| {} | {} |".format(key, totals[key]))
    lines += ["| **Total executed** | **{}** |".format(len(cases)),
              "| Total duration | {:.1f} min |".format(sum(c["duration"] for c in cases) / 60),
              ""]
    if failed:
        lines += ["## Failures ({})".format(len(failed)), ""]
        for case in failed:
            lines.append("- `{}/{}`".format(case["suite"], case["name"]))
            for message in case["failures"][:3]:
                lines.append("  - {}".format(message.replace("\n", " ")[:300]))
        lines.append("")
    if blocked:
        lines += ["## Not executed — skipped by the test plan ({})".format(len(blocked)), "",
                  "Tagged `// Regression` but listed in `skippedTests`; `-only-testing` does "
                  "not override that.", ""]
        lines += ["- `{}`".format(entry) for entry in blocked] + [""]
    if excluded_files:
        lines += ["## Files excluded from this job", "",
                  "Launched through a different pipeline:", ""]
        lines += ["- `{}`".format(entry) for entry in excluded_files] + [""]
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--xcresult", required=True)
    parser.add_argument("--junit", required=True)
    parser.add_argument("--summary")
    parser.add_argument("--blocked-json",
                        help="--format json output of find_regression_tests.py")
    args = parser.parse_args()

    try:
        tests = xcresulttool("tests", args.xcresult)
    except UnreadableBundle as error:
        print("ERROR: could not read {} -> {}".format(args.xcresult, error), file=sys.stderr)
        return 3
    cases = collect_cases(tests.get("testNodes", []))

    blocked, excluded_files = [], []
    if args.blocked_json and os.path.exists(args.blocked_json):
        with open(args.blocked_json, encoding="utf-8") as handle:
            selection = json.load(handle)
        blocked = selection.get("blockedByPlan", [])
        excluded_files = selection.get("excludedFiles", [])

    os.makedirs(os.path.dirname(os.path.abspath(args.junit)), exist_ok=True)
    tree = build_junit(cases, "XCUITests.Regression")
    ET.indent(tree, space="  ")
    tree.write(args.junit, encoding="utf-8", xml_declaration=True)

    if args.summary:
        write_summary(args.summary, cases, blocked, excluded_files, args.xcresult)

    failed = sum(1 for c in cases if c["result"] == "Failed")
    print("{} tests in the report, {} failed -> {}".format(len(cases), failed, args.junit),
          file=sys.stderr)
    if not cases:
        # A bundle with no cases means the run never started (invalid destination,
        # dead simulator...). Publishing it as an empty report would be a false green.
        print("ERROR: the .xcresult contains no test", file=sys.stderr)
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())

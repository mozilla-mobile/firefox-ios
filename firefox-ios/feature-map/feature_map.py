#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = ["pyyaml"]
# ///
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""Attributes Firefox iOS source code to product features.

Reads features.yml (the feature IDs) and feature-map.yml (path and symbol rules)
and resolves every Swift file under the configured roots to exactly one feature.
Rules are order-independent: an exact file path beats a glob, and among globs the
one with more literal path segments wins. Two equally specific matching rules are
an error.

Symbol rules refine a file rule for large files that serve several features. They
match function names reported by `xcrun xccov`, so they only take effect in the
`coverage` command. Closures are attributed to the function that contains them.

Commands:
    check               Fail if any file is unmapped, a rule is ambiguous, a rule
                        matches no files, or a feature ID is unknown.
    files               Print the resolved feature for every file as CSV.
    lines               Print source line totals per feature as CSV.
    coverage REPORT     Print executable/covered lines per feature as CSV, from
                        `xcrun xccov view --report --json <bundle>.xcresult`.

Run with `uv run firefox-ios/feature-map/feature_map.py <command>` from the
repository root, or with any Python that has PyYAML installed.
"""

import argparse
import collections
import csv
import json
import os
import re
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
CLOSURE_PREFIX = re.compile(r"^(?:(?:implicit )?closure #\d+ (?:\(\) )?in )+")


class Rule:
    def __init__(self, raw, index):
        self.path = raw["path"]
        self.feature = raw["feature"]
        self.by = raw.get("by", "human")
        self.symbols = [(re.compile(s["match"]), s["feature"]) for s in raw.get("symbols", [])]
        self.index = index
        self.is_glob = any(c in self.path for c in "*?[")
        self.regex = re.compile(glob_to_regex(self.path))
        literal_segments = [s for s in self.path.split("/") if not any(c in s for c in "*?[")]
        self.specificity = (0 if self.is_glob else 1, len(literal_segments), len(self.path))

    def matches(self, path):
        return self.regex.fullmatch(path) is not None

    def feature_for_symbol(self, function_name):
        name = CLOSURE_PREFIX.sub("", function_name)
        for pattern, feature in self.symbols:
            if pattern.search(name):
                return feature
        return self.feature


def glob_to_regex(pattern):
    out, i = [], 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif pattern.startswith("**", i):
            out.append(".*")
            i += 2
        elif pattern[i] == "*":
            out.append("[^/]*")
            i += 1
        elif pattern[i] == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    return "".join(out)


def load():
    with open(os.path.join(HERE, "features.yml")) as f:
        features = yaml.safe_load(f)
    with open(os.path.join(HERE, "feature-map.yml")) as f:
        mapping = yaml.safe_load(f)
    ids = {}
    for group in ("features", "shared", "excluded"):
        for item in features.get(group, []):
            ids[item["id"]] = item
    rules = [Rule(r, i) for i, r in enumerate(mapping["rules"])]
    return ids, mapping["roots"], rules


def source_files(roots):
    files = []
    for root in roots:
        for dirpath, dirnames, filenames in os.walk(os.path.join(REPO_ROOT, root)):
            dirnames[:] = sorted(d for d in dirnames if not d.startswith("."))
            for name in sorted(filenames):
                if name.endswith(".swift"):
                    files.append(os.path.relpath(os.path.join(dirpath, name), REPO_ROOT))
    return files


def resolve(path, rules):
    """Returns (rule, error) for the most specific rule matching `path`."""
    matching = [r for r in rules if r.matches(path)]
    if not matching:
        return None, "unmapped"
    matching.sort(key=lambda r: r.specificity, reverse=True)
    if len(matching) > 1 and matching[0].specificity == matching[1].specificity:
        return None, f"ambiguous: {matching[0].path} vs {matching[1].path}"
    return matching[0], None


def count_lines(path):
    with open(os.path.join(REPO_ROOT, path), errors="ignore") as f:
        return sum(1 for _ in f)


def cmd_check(ids, roots, rules):
    errors = []
    for r in rules:
        for feature in [r.feature] + [f for _, f in r.symbols]:
            if feature not in ids:
                errors.append(f"unknown feature {feature} in rule {r.path}")
            elif ids[feature].get("ios") is False:
                errors.append(f"feature {feature} is marked ios: false but rule {r.path} uses it")
    used = set()
    for path in source_files(roots):
        rule, error = resolve(path, rules)
        if error:
            errors.append(f"{error}: {path}")
        else:
            used.add(rule.index)
    for r in rules:
        if r.index not in used:
            errors.append(f"rule matches no files: {r.path}")
    for e in errors:
        print(e)
    pending = sum(1 for r in rules if r.by == "ai")
    print(f"{len(rules)} rules, {pending} awaiting human review, {len(errors)} problems", file=sys.stderr)
    return 1 if errors else 0


def cmd_files(ids, roots, rules):
    w = csv.writer(sys.stdout)
    w.writerow(["path", "feature", "rule", "by", "has_symbol_rules", "lines"])
    for path in source_files(roots):
        rule, error = resolve(path, rules)
        if error:
            w.writerow([path, error.upper(), "", "", "", count_lines(path)])
        else:
            w.writerow([path, rule.feature, rule.path, rule.by, bool(rule.symbols), count_lines(path)])
    return 0


def write_totals(ids, totals, columns):
    w = csv.writer(sys.stdout)
    w.writerow(["feature", "area", "name"] + columns)
    for feature in sorted(totals, key=lambda f: (f not in ids, ids.get(f, {}).get("area", "~"), f)):
        meta = ids.get(feature, {})
        w.writerow([feature, meta.get("area", ""), meta.get("name", "")] + [totals[feature][c] for c in columns])


def cmd_lines(ids, roots, rules):
    totals = collections.defaultdict(collections.Counter)
    for path in source_files(roots):
        rule, error = resolve(path, rules)
        feature = rule.feature if rule else "UNMAPPED"
        totals[feature]["files"] += 1
        totals[feature]["lines"] += count_lines(path)
    write_totals(ids, totals, ["files", "lines"])
    return 0


def repo_relative(path, in_scope):
    """Maps an absolute path from another checkout or CI machine onto a repo-relative source path."""
    parts = path.split("/")
    for i in range(len(parts)):
        candidate = "/".join(parts[i:])
        if candidate in in_scope:
            return candidate
    return None


def cmd_coverage(ids, roots, rules, report_path):
    with open(report_path) as f:
        report = json.load(f)
    in_scope = set(source_files(roots))
    totals = collections.defaultdict(collections.Counter)
    seen = set()
    for target in report.get("targets", []):
        for entry in target.get("files", []):
            path = repo_relative(entry["path"], in_scope)
            if path is None or path in seen:
                continue
            seen.add(path)
            rule, error = resolve(path, rules)
            functions = entry.get("functions") or [{"name": "", **entry}]
            for fn in functions:
                feature = rule.feature_for_symbol(fn["name"]) if rule else "UNMAPPED"
                totals[feature]["executable_lines"] += fn["executableLines"]
                totals[feature]["covered_lines"] += fn["coveredLines"]
            if rule:
                for feature in {rule.feature_for_symbol(fn["name"]) for fn in functions}:
                    totals[feature]["files_with_coverage_data"] += 1
    for path in in_scope - seen:
        rule, _ = resolve(path, rules)
        feature = rule.feature if rule else "UNMAPPED"
        totals[feature]["files_without_coverage_data"] += 1
        totals[feature]["source_lines_without_coverage_data"] += count_lines(path)
    for t in totals.values():
        t["line_coverage_pct"] = round(100 * t["covered_lines"] / t["executable_lines"], 1) if t["executable_lines"] else ""
    write_totals(ids, totals, ["executable_lines", "covered_lines", "line_coverage_pct",
                               "files_with_coverage_data", "files_without_coverage_data",
                               "source_lines_without_coverage_data"])
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("check")
    sub.add_parser("files")
    sub.add_parser("lines")
    cov = sub.add_parser("coverage")
    cov.add_argument("report", help="JSON from `xcrun xccov view --report --json <bundle>.xcresult`")
    args = parser.parse_args()
    ids, roots, rules = load()
    if args.command == "check":
        return cmd_check(ids, roots, rules)
    if args.command == "files":
        return cmd_files(ids, roots, rules)
    if args.command == "lines":
        return cmd_lines(ids, roots, rules)
    return cmd_coverage(ids, roots, rules, args.report)


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Match review-context.toml against the changed files and load the guidance.

Follows bugbug's review helper (bugbug/tools/code_review/review_context.py):
the rules are parsed and validated by bugbug's schema module, rules run in
priority order, and each file is loaded once however many rules match it. Only
the matched guidance reaches Claude, so Claude never reads the rules itself.

The guidance comes from the base branch commit the workflow runs on, never
from the pull request. Bugzilla, review and patch predicates never match here:
a GitHub pull request has no Bugzilla bug or Phabricator metadata.

Needs bugbug's review_context_schema.py on PYTHONPATH.

Usage: load_guidance.py --repo OWNER/NAME --ref SHA --config review-context.toml
                        --files files.json --out guidance.md
"""

import argparse
import fnmatch
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from urllib.parse import quote

from common import gh_api_raw
from review_context_schema import (
    AllFilesPredicate,
    AllPredicate,
    AnyFilePredicate,
    AnyPredicate,
    FilePredicate,
    LoadFileAction,
    NotPredicate,
    Predicate,
    ReviewContextConfig,
    validate_review_context_file,
)


@dataclass
class Guidance:
    path: str
    rules: list[str] = field(default_factory=list)


def changed_paths(files: list[dict]) -> set[str]:
    """The paths a pull request adds or modifies; removed files have no rules to apply."""
    return {f["filename"] for f in files if f["status"] != "removed"}


def file_matches(predicate: FilePredicate, path: str) -> bool:
    if predicate.include and not any(fnmatch.fnmatchcase(path, p) for p in predicate.include):
        return False
    if predicate.exclude and any(fnmatch.fnmatchcase(path, p) for p in predicate.exclude):
        return False
    return not predicate.ext or any(path.endswith(ext) for ext in predicate.ext)


def predicate_matches(predicate: Predicate, paths: set[str]) -> bool:
    match predicate:
        case AllPredicate(children=children):
            return all(predicate_matches(child, paths) for child in children)
        case AnyPredicate(children=children):
            return any(predicate_matches(child, paths) for child in children)
        case NotPredicate(child=child):
            return not predicate_matches(child, paths)
        case AnyFilePredicate(predicate=files):
            return any(file_matches(files, path) for path in paths)
        case AllFilesPredicate(predicate=files):
            return bool(paths) and all(file_matches(files, path) for path in paths)
    # Bugzilla, review and patch predicates: no such metadata on a GitHub PR.
    return False


def match_guidance(
    config: ReviewContextConfig, paths: set[str], repo: str
) -> tuple[list[Guidance], list[str]]:
    """The files to load, in rule priority order, and the actions that can't run here."""
    guidance: dict[str, Guidance] = {}
    skipped: list[str] = []
    ordered = sorted(enumerate(config.rules), key=lambda item: (-item[1].priority, item[0]))
    for _, rule in ordered:
        if not predicate_matches(rule.when, paths):
            continue
        for action in rule.load:
            local = (
                isinstance(action, LoadFileAction)
                and action.branch is None
                and (action.repo is None or action.repo.lower() == repo.lower())
            )
            if not local:
                skipped.append(f"{rule.name}: {action}")
                continue
            guidance.setdefault(action.path, Guidance(action.path)).rules.append(rule.name)
    return list(guidance.values()), skipped


def render(loaded: list[tuple[Guidance, str]], missing: list[Guidance], ref: str) -> str:
    parts = [
        "# Review guidance",
        "",
        f"Loaded from the base branch at {ref[:12]} because review-context.toml rules "
        "matched the changed files.",
        "",
    ]
    for item, body in loaded:
        rules = ", ".join(item.rules)
        parts += [f'<guidance path="{item.path}" rules="{rules}">', body.strip(), "</guidance>", ""]
    if missing:
        parts += ["Couldn't be loaded: " + ", ".join(item.path for item in missing), ""]
    if not loaded and not missing:
        parts.append("(no rules matched)")
    return "\n".join(parts)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--ref", required=True)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--files", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    try:
        config = validate_review_context_file(args.config)
    except Exception as exc:
        sys.exit(f"{args.config} is invalid: {exc}")

    paths = changed_paths(json.loads(args.files.read_text()))
    guidance, skipped = match_guidance(config, paths, args.repo)
    for action in skipped:
        print(f"::warning::Not loading {action}: only files from this repository are supported")

    loaded, missing = [], []
    for item in guidance:
        try:
            body = gh_api_raw(f"repos/{args.repo}/contents/{quote(item.path)}?ref={args.ref}")
        except Exception as exc:
            print(f"::warning::Couldn't load {item.path}: {exc}")
            missing.append(item)
            continue
        loaded.append((item, body))
        print(f"Loaded {item.path} for {', '.join(item.rules)}")

    args.out.write_text(render(loaded, missing, args.ref))


if __name__ == "__main__":
    main()

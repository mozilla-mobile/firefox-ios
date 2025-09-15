#!/usr/bin/python3
from pathlib import Path
from urllib.request import urlopen
import argparse
import fileinput
import hashlib
import json
import shutil
import subprocess
import sys
import tarfile
import tempfile

ROOT_DIR        = Path(__file__).parent.parent
PACKAGE_SWIFT   = ROOT_DIR / "MozillaRustComponents" / "Package.swift"
# Latest nightly.json produced by application-services CI
NIGHTLY_JSON_URL = (
    "https://firefox-ci-tc.services.mozilla.com/api/index/v1/"
    "task/project.application-services.v2.nightly.latest/artifacts/"
    "public%2Fbuild%2Fnightly.json"
)


def main() -> None:
    args     = parse_args()
    version  = VersionInfo(args.version)
    BRANCH   = "rcs-auto-update"
    TITLE    = f"(Local AS flow) Nightly auto-update ({version.swift_version})"

    if not args.in_place:
        # Ensure we have the latest remote copy of the update branch (if any)
        subprocess.run(["git", "fetch", args.remote, BRANCH], check=False)

        # Create (or reset) our working branch
        remote_ref = f"refs/remotes/{args.remote}/{BRANCH}"
        if subprocess.run(
            ["git", "rev-parse", "--verify", remote_ref],
            stdout=subprocess.DEVNULL,
        ).returncode == 0:
            subprocess.check_call(["git", "checkout", "-B", BRANCH, remote_ref])
        else:
            subprocess.check_call(["git", "checkout", "-B", BRANCH, args.base])
    else:
        print(
            "In-place arg passed: skipping branch checkout and all commit/push steps.",
            file=sys.stderr,
        )

    # Apply the nightly (or specified) update
    update_source(version, git_add=not args.in_place)

    if not repo_has_changes():
        print("No changes detected, quitting")
        return

    if args.in_place:
        print("Updates applied in-place. Review, stage, and commit manually if desired.")
        return

    # Stage everything
    subprocess.check_call(["git", "add", "-A", "MozillaRustComponents"])

    # Actually check if we have anything locally
    has_staged = (
        subprocess.run(
            ["git", "diff", "--cached", "--quiet"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        != 0
    )

    if not has_staged:
        print("No changes detected, quitting")
        return

    # Commit
    subprocess.check_call(
        [
            "git",
            "commit",
            "--author",
            "Firefox Sync Engineering <sync-team@mozilla.com>",
            "--message",
            TITLE,
        ]
    )

    # Push and open / update the PR
    if args.push:
        subprocess.check_call(
            ["git", "push", "--force-with-lease", "-u", args.remote, BRANCH]
        )

        result = subprocess.run(
            ["gh", "pr", "view", BRANCH, "--json", "state", "--jq", ".state"],
            text=True,
            capture_output=True,
        )

        if result.returncode == 0 and result.stdout.strip() == "OPEN":
            print("PR already open, branch updated in place")
            return

        subprocess.check_call(
            [
                "gh",
                "pr",
                "create",
                "--title",
                TITLE,
                "--body",
                f"Automatically generated app-services nightly build for `{version.swift_version}`.",
                "--base",
                args.base,
                "--head",
                BRANCH,
                "--label",
                "auto-update,nightly",
            ]
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="update_from_application_services.py")
    parser.add_argument("version", help='Version to use (or literal `"nightly"`).')
    parser.add_argument(
        "--in-place",
        action="store_true",
        help=(
            "Apply updates in the current working branch and skip creating/updating "
            "a branch, staging, committing, pushing, and PR creation."
        ),
    )
    parser.add_argument(
        "--push", action="store_true", help="Push changes and create / update PR"
    )
    parser.add_argument(
        "--remote", default="origin", help="Remote repository name (default: origin)"
    )
    parser.add_argument(
        "--base",
        default="main",
        help="Branch the PR should target (default: main)",
    )
    return parser.parse_args()

class VersionInfo:
    """Encapsulates converting an A-S version into the semver Swift expects."""

    def __init__(self, app_services_version: str):
        self.is_nightly = app_services_version == "nightly"
        if self.is_nightly:
            with urlopen(NIGHTLY_JSON_URL) as stream:
                app_services_version = json.loads(stream.read())["version"]

        comps = app_services_version.split(".")

        if len(comps) == 2:
            # 2-component A-S version → 3-component Swift version
            self.app_services_version = app_services_version
            self.swift_version = f"{comps[0]}.0.{comps[1]}"
        elif len(comps) == 3:
            self.app_services_version = app_services_version
            self.swift_version = app_services_version
        else:
            raise ValueError(f"Invalid app_services_version: {app_services_version}")


def update_source(version: VersionInfo, *, git_add: bool = True) -> None:
    print("Updating Package.swift xcframework info …", flush=True)
    update_package_swift(version, git_add=git_add)

    print("Updating Swift wrapper sources …", flush=True)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        extract_tarball(version, tmp_path)
        replace_all_files(tmp_path)


def update_package_swift(version: VersionInfo, *, git_add: bool = True) -> None:
    url          = swift_artifact_url(version, "MozillaRustComponents.xcframework.zip")
    focus_url    = swift_artifact_url(version, "FocusRustComponents.xcframework.zip")
    checksum     = compute_checksum(url)
    focus_sum    = compute_checksum(focus_url)

    replacements = {
        "let version =":       f'let version = "{version.swift_version}"',
        "let url =":           f'let url = "{url}"',
        "let checksum =":      f'let checksum = "{checksum}"',
        "let focusUrl =":      f'let focusUrl = "{focus_url}"',
        "let focusChecksum =": f'let focusChecksum = "{focus_sum}"',
    }

    for line in fileinput.input(PACKAGE_SWIFT, inplace=True):
        for start, repl in replacements.items():
            if line.strip().startswith(start):
                line = f"{repl}\n"
                break
        sys.stdout.write(line)

    if git_add:
        subprocess.check_call(["git", "add", PACKAGE_SWIFT])

def extract_tarball(version: VersionInfo, dest: Path) -> None:
    tar_url = swift_artifact_url(version, "swift-components.tar.xz")
    with urlopen(tar_url) as stream:
        with tarfile.open(fileobj=stream, mode="r|xz") as tar:
            for member in tar:
                if not Path(member.name).name.startswith("._"):
                    tar.extract(member, path=dest)


def replace_all_files(tmp_dir: Path) -> None:
    replace_files(
        tmp_dir / "swift-components/all/Generated",
        "MozillaRustComponents/Sources/MozillaRustComponentsWrapper/Generated",
    )
    replace_files(
        tmp_dir / "swift-components/focus/Generated",
        "MozillaRustComponents/Sources/FocusRustComponentsWrapper/Generated"
    )


def replace_files(source_dir: Path, repo_dir: str) -> None:
    shutil.rmtree(repo_dir)
    shutil.copytree(source_dir, repo_dir)

    # prune unnecessary headers / modulemaps
    for p in Path(repo_dir).rglob("*"):
        if (p.suffix == ".h" and p.name != "RustViaductFFI.h") or p.suffix == ".modulemap":
            p.unlink()

def compute_checksum(url: str) -> str:
    with urlopen(url) as stream:
        return hashlib.sha256(stream.read()).hexdigest()


def swift_artifact_url(version: VersionInfo, filename: str) -> str:
    if version.is_nightly:
        return (
            "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/"
            "project.application-services.v2"
            f".swift.{version.app_services_version}/artifacts/public/build/{filename}"
        )
    return (
        "https://archive.mozilla.org/pub/app-services/releases/"
        f"{version.app_services_version}/{filename}"
    )


def repo_has_changes() -> bool:
    return (
        subprocess.run(
            ["git", "diff-index", "--quiet", "HEAD"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        != 0
    )

if __name__ == "__main__":
    main()

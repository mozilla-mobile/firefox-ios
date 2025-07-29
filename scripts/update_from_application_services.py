#!/usr/bin/python3

from pathlib import Path
from urllib.request import urlopen
import argparse
import fileinput
import hashlib
import json
import subprocess
import shutil
import sys
import tarfile
import tempfile

ROOT_DIR = Path(__file__).parent.parent
PACKAGE_SWIFT = ROOT_DIR / "MozillaRustComponents" / "Package.swift"
# Latest nightly nightly.json file from the taskcluster index
NIGHTLY_JSON_URL = "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.nightly.latest/artifacts/public%2Fbuild%2Fnightly.json"

def main():
    args = parse_args()
    version = VersionInfo(args.version)

    BRANCH = "rcs-auto-update"
    TITLE = f"Nightly auto-update ({version.swift_version})"

    update_source(version)
    if not repo_has_changes():
        print("No changes detected, quitting")
        sys.exit(0)
    # Make a branch for the PR
    subprocess.check_call(["git", "checkout", "-B", BRANCH])
    subprocess.check_call([
        "git",
        "commit",
        "--author",
        "Firefox Sync Engineering <sync-team@mozilla.com>",
        "--message",
        TITLE
    ])
    if args.push:
        subprocess.check_call(["git", "push", "--force-with-lease", "-u", args.remote, BRANCH])

        result = subprocess.run(
            ["gh", "pr", "view", BRANCH, "--json", "state", "--jq", ".state"],
            text=True,
            capture_output=True,
        )
        # If the branch already has an open PR, nothing else to do
        if result.returncode == 0 and result.stdout.strip() == "OPEN":
            print("PR already open – branch updated in place")
            return

        # Otherwise create one
        subprocess.check_call([
            "gh", "pr", "create",
            "--title",  TITLE,
            "--body",  f"Automatically generated app-services nightly build for `{version.swift_version}`.",
            "--base",  "main",
            "--head",  BRANCH,
            "--label", "auto-update,nightly"
        ])

def update_source(version):
    print("Updating Package.swift xcframework info", flush=True)
    update_package_swift(version)

    print("Updating swift source files", flush=True)
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_dir = Path(temp_dir)
        extract_tarball(version, temp_dir)
        replace_all_files(temp_dir)

def parse_args():
    parser = argparse.ArgumentParser(prog='build-and-test-swift.py')
    parser.add_argument('version', help="version to use (or `nightly`)")
    parser.add_argument('--push', help="Push changes to remote repository",
                        action="store_true")
    parser.add_argument('--remote', help="Remote repository name", default="origin")
    return parser.parse_args()

class VersionInfo:
    def __init__(self, app_services_version):
        self.is_nightly = app_services_version == "nightly"
        if self.is_nightly:
            with urlopen(NIGHTLY_JSON_URL) as stream:
                data = json.loads(stream.read())
                app_services_version = data['version']
        components = app_services_version.split(".")
        # check if the app services version is using the 2 or 3 component semver
        if len(components) == 2:
            # app_services_version is the 2-component version we normally use for application services
            self.app_services_version = app_services_version
            # swift_version is the 3-component version we use for Swift so that it's semver-compatible
            self.swift_version = f"{components[0]}.0.{components[1]}"
        # if it's 3-component, use as-is
        elif len(components) == 3:
            self.app_services_version = app_services_version
            self.swift_version = app_services_version
        else:
            raise ValueError(f"Invalid app_services_version: {app_services_version}")

def rev_exists(branch):
    result = subprocess.run(
            ["git", "rev-parse", "--verify", branch],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL)
    return result.returncode == 0

def update_package_swift(version):
    url = swift_artifact_url(version, "MozillaRustComponents.xcframework.zip")
    focus_url = swift_artifact_url(version, "FocusRustComponents.xcframework.zip")
    checksum = compute_checksum(url)
    focus_checksum = compute_checksum(focus_url)
    replacements = {
        "let version =": f'let version = "{version.swift_version}"',
        "let url =": f'let url = "{url}"',
        "let checksum =": f'let checksum = "{checksum}"',
        "let focusUrl =": f'let focusUrl = "{focus_url}"',
        "let focusChecksum =": f'let focusChecksum = "{focus_checksum}"',
    }
    for line in fileinput.input(PACKAGE_SWIFT, inplace=True):
        for (line_start, replacement) in replacements.items():
            if line.strip().startswith(line_start):
                line = f"{replacement}\n"
                break
        sys.stdout.write(line)
    subprocess.check_call(["git", "add", PACKAGE_SWIFT])

def compute_checksum(url):
    with urlopen(url) as stream:
        return hashlib.sha256(stream.read()).hexdigest()

def extract_tarball(version, temp_dir):
    with urlopen(swift_artifact_url(version, "swift-components.tar.xz")) as f:
        with tarfile.open(mode="r|xz", fileobj=f) as tar:
            for member in tar:
                if not Path(member.name).name.startswith("._"):
                    tar.extract(member, path=temp_dir)

def replace_all_files(temp_dir):
    replace_files(temp_dir / "swift-components/all", "MozillaRustComponents/Sources/MozillaRustComponentsWrapper")
    #replace_files(temp_dir / "swift-components/focus", "MozillaRustComponents/Sources/FocusRustComponentsWrapper")
    subprocess.check_call(["git", "add", "MozillaRustComponents"])

"""
Replace files in the git repo with files extracted from the tarball

Args:
    source_dir: directory to look for sources
    repo_dir: relative directory in the repo to replace files in
"""
def replace_files(source_dir, repo_dir):
    shutil.rmtree(repo_dir)
    shutil.copytree(source_dir, repo_dir)
    # Small hack to delete unnecessary *.h files (keep RustViaductFFi.h)
    # and modulemap files
    for p in Path(repo_dir).rglob("*"):
        if (
             (p.suffix == ".h" and p.name != "RustViaductFFI.h")
              or p.suffix == ".modulemap"
        ):
            p.unlink()

def swift_artifact_url(version, filename):
    if version.is_nightly:
        return ("https://firefox-ci-tc.services.mozilla.com"
                "/api/index/v1/task/project.application-services.v2"
                f".swift.{version.app_services_version}/artifacts/public/build/{filename}")
    else:
        return ("https://archive.mozilla.org"
                "/pub/app-services/releases/"
                f"{version.app_services_version}/{filename}")

def repo_has_changes():
    result = subprocess.run([
        "git",
        "diff-index",
        "--quiet",
        "HEAD",
    ])
    return result.returncode != 0

if __name__ == '__main__':
    main()

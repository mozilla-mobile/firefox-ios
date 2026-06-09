import json
import logging
import re
from github import Github

# Constants
KINGFISHER_REPO = "onevcat/Kingfisher"

BROWSERKIT_PACKAGE_SWIFT = "BrowserKit/Package.swift"
BROWSERKIT_SPM_PACKAGE = "BrowserKit/Package.resolved"
FIREFOX_SPM_PACKAGE = "firefox-ios/Client.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
SAMPLE_APP_SPM_PACKAGE = "SampleComponentLibraryApp/SampleComponentLibraryApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
FOCUS_SPM_PACKAGE = "focus-ios/Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
FIREFOX_PBXPROJ = "firefox-ios/Client.xcodeproj/project.pbxproj"

SPM_PACKAGES = [
    BROWSERKIT_SPM_PACKAGE,
    FIREFOX_SPM_PACKAGE,
    SAMPLE_APP_SPM_PACKAGE,
    FOCUS_SPM_PACKAGE,
]


def _init_logging():
    logging.basicConfig(
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        level=logging.INFO,
    )


def get_latest_kingfisher_version():
    """Fetch the latest release version and commit SHA from GitHub."""
    repo = Github().get_repo(KINGFISHER_REPO)
    latest_tag = repo.get_tags()[0]
    version = latest_tag.name
    revision = latest_tag.commit.sha
    return version, revision


def read_version_from_package_swift(filepath):
    """Read the current pinned version from BrowserKit/Package.swift."""
    try:
        with open(filepath) as f:
            content = f.read()
        match = re.search(r'exact:\s*"(\d+\.\d+\.\d+)"', content)
        return match.group(1) if match else None
    except FileNotFoundError as e:
        logging.error(f"File not found: {e}")
        return None


def read_version_from_resolved(filepath):
    """Read the current version and revision for Kingfisher from a Package.resolved.

    Handles both:
      - v3 format: uses "identity" (lowercase) and "location" keys
      - v1 format: uses "package" (capitalized) and "repositoryURL" keys (Focus/Blockzilla)
    """
    try:
        with open(filepath) as f:
            data = json.load(f)

        # v1 wraps pins under an "object" key
        pins = data.get("object", data).get("pins", [])
        for pin in pins:
            identity = pin.get("identity", pin.get("package", ""))
            if identity.lower() == "kingfisher":
                state = pin["state"]
                return state.get("version"), state.get("revision")
    except (FileNotFoundError, json.JSONDecodeError) as e:
        logging.error(f"Error reading {filepath}: {e}")
    return None, None


def compare_versions(current, latest):
    """Return True if latest is strictly newer than current."""
    def to_tuple(v):
        return tuple(int(x) for x in v.split("."))
    return to_tuple(latest) > to_tuple(current)


def read_version_from_pbxproj(filepath):
    """Read the current Kingfisher version from the XCRemoteSwiftPackageReference block in project.pbxproj."""
    try:
        with open(filepath) as f:
            content = f.read()
        # Match only the block definition (with */ = {), not comment-only references
        match = re.search(
            r'XCRemoteSwiftPackageReference "Kingfisher" \*/ = \{.*?version = (\d+\.\d+\.\d+);',
            content,
            re.DOTALL
        )
        return match.group(1) if match else None
    except FileNotFoundError as e:
        logging.error(f"File not found: {e}")
        return None


def update_pbxproj(filepath, new_version):
    """Update the Kingfisher version inside the XCRemoteSwiftPackageReference block in project.pbxproj."""
    try:
        with open(filepath, "r") as f:
            content = f.read()
        # Match only the block definition (with */ = {), not comment-only references
        updated = re.sub(
            r'(XCRemoteSwiftPackageReference "Kingfisher" \*/ = \{.*?version = )\d+\.\d+\.\d+(;)',
            rf'\g<1>{new_version}\2',
            content,
            flags=re.DOTALL
        )
        with open(filepath, "w") as f:
            f.write(updated)
        logging.info(f"Updated {filepath}")
    except (FileNotFoundError, IOError) as e:
        logging.error(f"Error updating {filepath}: {e}")


def update_file(filepath, old_version, new_version, old_revision, new_revision):
    """Replace the version and revision strings in a file."""
    try:
        with open(filepath, "r") as f:
            content = f.read()
        if old_version and new_version:
            content = content.replace(old_version, new_version)
        if old_revision and new_revision:
            content = content.replace(old_revision, new_revision)
        with open(filepath, "w") as f:
            f.write(content)
        logging.info(f"Updated {filepath}")
    except (FileNotFoundError, IOError) as e:
        logging.error(f"Error updating {filepath}: {e}")


def main():
    """
    STEPS
    1. Fetch latest Kingfisher tag from GitHub
    2. Update BrowserKit/Package.swift if its pinned version is behind latest
    3. Update each Package.resolved independently if its pinned version is behind latest
    4. Write newest_kingfisher_tag.txt if any file was changed (signals the workflow to open a PR)
    """
    _init_logging()

    latest_version, latest_revision = get_latest_kingfisher_version()
    logging.info(f"Latest Kingfisher on GitHub: {latest_version} ({latest_revision})")

    any_updated = False

    # Update BrowserKit/Package.swift if behind
    swift_version = read_version_from_package_swift(BROWSERKIT_PACKAGE_SWIFT)
    logging.info(f"Current Kingfisher in Package.swift: {swift_version}")
    if swift_version and compare_versions(swift_version, latest_version):
        logging.info(f"Updating Package.swift: {swift_version} -> {latest_version}")
        update_file(BROWSERKIT_PACKAGE_SWIFT, swift_version, latest_version, None, None)
        any_updated = True
    else:
        logging.info("Package.swift is already up to date.")

    # Update project.pbxproj if behind
    pbxproj_version = read_version_from_pbxproj(FIREFOX_PBXPROJ)
    logging.info(f"Current Kingfisher in project.pbxproj: {pbxproj_version}")
    if pbxproj_version and compare_versions(pbxproj_version, latest_version):
        logging.info(f"Updating project.pbxproj: {pbxproj_version} -> {latest_version}")
        update_pbxproj(FIREFOX_PBXPROJ, latest_version)
        any_updated = True
    else:
        logging.info("project.pbxproj is already up to date.")

    # Update each Package.resolved independently (v1 and v3 formats handled in read_version_from_resolved)
    for resolved_file in SPM_PACKAGES:
        file_version, file_revision = read_version_from_resolved(resolved_file)
        logging.info(f"Current Kingfisher in {resolved_file}: {file_version}")
        if file_version and file_revision and compare_versions(file_version, latest_version):
            logging.info(f"Updating {resolved_file}: {file_version} -> {latest_version}")
            update_file(resolved_file, file_version, latest_version, file_revision, latest_revision)
            any_updated = True
        elif file_version and file_revision:
            logging.info(f"{resolved_file} is already up to date.")
        else:
            logging.warning(f"Kingfisher entry not found in {resolved_file}, skipping.")

    if not any_updated:
        logging.info("All Kingfisher references are already up to date. Nothing to do.")
        return

    # Write the new tag so the workflow can use it in the PR title/branch name
    with open("test-fixtures/newest_kingfisher_tag.txt", "w") as f:
        f.write(latest_version + "\n")


if __name__ == "__main__":
    main()

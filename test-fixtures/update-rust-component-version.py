import re
import json
from github import Github

GITHUB_REPO = "mozilla/rust-components-swift"
PROJECT_FILE = "Client.xcodeproj/project.pbxproj"
SPM_PACKAGE_FILE = "Client.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"


def get_latest_tag(repo):
    all_tags = repo.get_tags()
    if not all_tags:
        raise ValueError("No tags found in rust-components-swift")
    return max(all_tags, key=lambda t: t.tagged_date)


def get_current_version():
    with open(PROJECT_FILE) as f:
        for line in f:
            if "https://github.com/mozilla/rust-components-swift" in line:
                version_line = next(f).strip()
                version_match = re.search(r'(\d+\.\d+\.\d+)', version_line)
                if version_match:
                    return version_match.group(1)
                else:
                    raise ValueError(
                        "Could not parse version from project file")
    raise ValueError("Could not find rust-components-swift in project file")


def update_project_file(version, commit):
    with open(PROJECT_FILE) as f:
        project_data = f.read()
    project_data = re.sub(
        r'(https://github.com/mozilla/rust-components-swift.git.*?)(\d+\.\d+\.\d+)', f'\\g<1>{version}', project_data)
    project_data = re.sub(
        r'(https://github.com/mozilla/rust-components-swift.git.*?)(commit )([\da-fA-F]+)', f'\\g<1>{commit}', project_data)
    with open(PROJECT_FILE, "w") as f:
        f.write(project_data)


def update_spm_package_file(version, commit):
    try:
        with open(SPM_PACKAGE_FILE) as f:
            data = json.load(f)
        for package in data["object"]["pins"]:
            if package["package"] == "rust-components-swift":
                package["state"]["version"] = version
                package["state"]["revision"] = commit
        with open(SPM_PACKAGE_FILE, "w") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        raise ValueError("Could not update SPM package file") from e


def main():
    g = Github()
    repo = g.get_repo(GITHUB_REPO)
    latest_tag = get_latest_tag(repo)
    latest_version = latest_tag.name
    latest_commit = latest_tag.commit.sha
    current_version = get_current_version()
    if latest_version != current_version:
        update_project_file(latest_version, latest_commit)
        update_spm_package_file(latest_version, latest_commit)
        print(
            f"Updated rust-components-swift to version {latest_version} ({latest_commit})")
    else:
        print(
            f"rust-components-swift is already up to date ({current_version})")


if __name__ == '__main__':
    main()

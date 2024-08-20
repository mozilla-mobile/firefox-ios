import argparse
import subprocess
from pathlib import Path

import yaml

parser = argparse.ArgumentParser("Options for android apk downloader")

parser.add_argument(
    "--test-files", nargs="+", help="List of test files to generate tests from"
)
args = parser.parse_args()


def search_for_smoke_tests(tests_name):
    """Searches for smoke tests within the requested test module."""
    path = Path().cwd()
    path = path.parent / "XCUITests"
    files = sorted([x for x in path.iterdir() if x.is_file()])
    locations = []
    file_name = None
    test_names = []

    for name in files:
        if tests_name in name.name:
            file_name = name
            break

    with open(file_name, "r") as file:
        code = file.read().split(" ")
        code = [item for item in code if item != ""]
        for count, item in enumerate(code):
            if "class" in item:
                locations.append(count)
            if "smoketest" in item.lower():
                locations.append(count)

        test_names.append(code[locations[0] + 1].strip(":"))

        for location in locations:
            for count in range(5): # loop forward to get 'func' location and then test name
                if "func" in code[location + count]:
                    test_name = code[location + count + 1]
                    test_names.append(test_name)
                    break
    return test_names


def create_test_file():
    """Create the python file to hold the tests."""

    path = Path().cwd()
    filename = "test_smoke_scenarios.py"
    final_path = path / filename

    if final_path.exists():
        print("File Exists, you need to delete it to create a new one.")
        exit
    # file exists
    subprocess.run([f"touch {final_path}"], encoding="utf8", shell=True)
    assert final_path.exists()
    with open(final_path, "w") as file:
        file.write("import time\n\nimport pytest\n\n")


def generate_smoke_tests(tests_names=None):
    """Generate pytest code for the requested tests."""
    pytest_file = Path().cwd() / "test_smoke_scenarios.py"
    tests = []
    module_name = tests_names[0]

    for test in tests_names[1:]:
        if "BaseTestCase" in test:
            continue
        if "test" not in test:
            continue
        test_name = test.replace("(", "").replace(")", "")
        tests.append(
            f"""
@pytest.mark.smoke
def test_smoke_{test_name}(xcodebuild, setup_experiment, start_app, experiment_branch, check_ping_for_experiment):
    xcodebuild.install(boot=False)
    setup_experiment()
    time.sleep(5)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", build=False,erase=False)
    start_app()
    xcodebuild.test("XCUITests/{module_name}/{test_name}", build=False, erase=False)
"""
        )
    with open(pytest_file, "a") as file:
        for item in tests:
            file.writelines(f"{item}")


if __name__ == "__main__":
    test_modules = []
    create_test_file()
    args = parser.parse_args()
    if args.test_files:
        test_modules = args.test_files
    else:
        with open("variables.yaml", "r") as file:
            tests = yaml.safe_load(file)
            test_modules = [test for test in tests.get("smoke_tests")]
    for item in test_modules:
        try: # incase a test file gets deleted this will alllow the program to run
            tests = search_for_smoke_tests(item)
        except TypeError:
            continue
        generate_smoke_tests(tests)

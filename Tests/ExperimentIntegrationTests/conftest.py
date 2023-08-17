import json
import os
from pathlib import Path
import subprocess

import pytest
import requests

## MUST REMOVE WHEN SYNCINTEGRATIONTEST FOLDER IS MOVED
import sys

sys.path.append("../../")

from SyncIntegrationTests.xcodebuild import XCodeBuild
from SyncIntegrationTests.xcrun import XCRun

KLAATU_SERVER_URL = "http://localhost:1378"
KLAATU_LOCAL_SERVER_URL = "http://localhost:1378"

here = Path("./")


def load_branches():
    branches = []
    data = requests.get(f"{KLAATU_SERVER_URL}/experiment").json()
    for item in reversed(data):
        if isinstance(item, dict):
            exit()
        else:
            data = item
            break
    experiment = requests.get(data).json()
    for item in experiment["branches"]:
        branches.append(item["slug"])
    return branches


@pytest.fixture
def xcodebuild_log(request, tmpdir):
    xcodebuild_log = str(tmpdir.join("xcodebuild.log"))
    request.config._xcodebuild_log = xcodebuild_log
    yield xcodebuild_log


@pytest.fixture(scope="session", autouse=True)
def fixture_build_fennec():
    xcrun = XCRun()
    hold = None
    command = "xcodebuild build -project Client.xcodeproj -scheme Fennec -configuration Fennec -sdk iphonesimulator"
    try:
        subprocess.check_output(
            command,
            cwd=os.chdir("../../"),
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            shell=True)
    except subprocess.CalledProcessError:
        raise


@pytest.fixture
def xcodebuild(xcodebuild_log):
    yield XCodeBuild(xcodebuild_log, scheme="Fennec", test_plan="ExperimentIntegrationTests")


@pytest.fixture(name="start_app")
def fixture_start_app():
    def _():
        command = f"nimbus-cli --app firefox_ios --channel developer open"
        out = subprocess.check_output(
            command,
            cwd=os.path.join(here, os.pardir),
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            shell=True,
        )
        print(out)

    return _


@pytest.fixture(name="experiment_data")
def fixture_experiment_data(experiment_url):
    data = requests.get(experiment_url).json()
    del data["branches"][0]["features"][0]["value"]["message-under-experiment"]
    for item in data["branches"][0]["features"][0]["value"]["messages"].values():
        for count, trigger in enumerate(item["trigger"]):
            if "USER_EN_SPEAKER" not in trigger:
                del item["trigger"][count]
    return [data]


@pytest.fixture(name="experiment_url", scope="module")
def fixture_experiment_url():
    data = requests.get(f"{KLAATU_LOCAL_SERVER_URL}/experiment").json()
    url = None
    for item in data:
        if isinstance(item, dict):
            continue
        else:
            url = item
    yield url
    return_data = {"url": url}
    requests.put(f"{KLAATU_SERVER_URL}/experiment", json=return_data)


@pytest.fixture(name="json_data")
def fixture_json_data(tmp_path, experiment_data):
    path = tmp_path / "data"
    path.mkdir()
    json_path = path / "data.json"
    with open(json_path, "w", encoding="utf-8") as f:
        # URL of experiment/klaatu server
        data = {"data": experiment_data}
        json.dump(data, f)
    return json_path


@pytest.fixture(name="experiment_slug")
def fixture_experiment_slug(experiment_data):
    return experiment_data[0]["slug"]


@pytest.fixture(name="send_test_results", autouse=True)
def fixture_send_test_results():
    yield
    here = Path()

    with open(f"{here.resolve()}/results/index.html", "rb") as f:
        files = {"file": f}
        requests.post(f"{KLAATU_SERVER_URL}/test_results", files=files)


@pytest.fixture(name="setup_experiment", params=load_branches(), autouse=True)
def setup_experiment(experiment_slug, json_data, request):
    def _setup_experiment():
        command = f"nimbus-cli --app firefox_ios --channel developer enroll {experiment_slug} --branch {request.param} --file {json_data} --reset-app"
        out = subprocess.check_output(
            command,
            cwd=os.path.join(here, os.pardir),
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            shell=True,
        )

    return _setup_experiment

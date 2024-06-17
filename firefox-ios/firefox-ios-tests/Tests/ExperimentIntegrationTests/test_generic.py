import time

import pytest


@pytest.mark.smoke
def test_experiment_unenrolls_after_studies_toggle(xcodebuild, setup_experiment, start_app, load_branches):
    xcodebuild.install(boot=False)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testAppStartup", build=False, erase=False)
    setup_experiment()
    time.sleep(5)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", build=False, erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testStudiesToggleDisablesExperiment", build=False, erase=False
    )

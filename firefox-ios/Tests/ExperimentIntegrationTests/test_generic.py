import pytest

@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_experiment_unenrolls_after_studies_toggle(xcodebuild, setup_experiment, start_app, load_branches):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testStudiesToggleDisablesExperiment", erase=False
    )

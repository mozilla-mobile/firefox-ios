import pytest


@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_survey_navigates_correctly(xcodebuild, setup_experiment, start_app, load_branches):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageNavigatesCorrectly", erase=False
    )

@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_survey_no_thanks_navigates_correctly(xcodebuild, setup_experiment, start_app, load_branches):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageNoThanksNavigatesCorrectly", erase=False
    )

@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_survey_landscape_looks_correct(xcodebuild, setup_experiment, start_app, load_branches):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageLandscapeUILooksCorrect", erase=False
    )

@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_homescreen_survey_navigates_correctly(xcodebuild, setup_experiment, start_app, load_branches):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testHomeScreenMessageNavigatesCorrectly", erase=False
    )

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import pytest


@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_survey_navigates_correctly(xcodebuild, setup_experiment, start_app, load_branches, check_ping_for_experiment):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageNavigatesCorrectly", erase=False
    )
    assert check_ping_for_experiment(reason="enrollment", branch=load_branches[0])

@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_survey_no_thanks_navigates_correctly(xcodebuild, setup_experiment, start_app, load_branches, check_ping_for_experiment):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageNoThanksNavigatesCorrectly", erase=False
    )
    assert check_ping_for_experiment(reason="enrollment", branch=load_branches[0])

@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_survey_landscape_looks_correct(xcodebuild, setup_experiment, start_app, load_branches, check_ping_for_experiment):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageLandscapeUILooksCorrect", erase=False
    )
    assert check_ping_for_experiment(reason="enrollment", branch=load_branches[0])

@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_homescreen_survey_navigates_correctly(xcodebuild, setup_experiment, start_app, load_branches, check_ping_for_experiment):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testHomeScreenMessageNavigatesCorrectly", erase=False
    )
    assert check_ping_for_experiment(reason="enrollment", branch=load_branches[0])

@pytest.mark.parametrize("load_branches", [("branch")], indirect=True)
def test_homescreen_survey_dismisses_correctly(xcodebuild, setup_experiment, start_app, load_branches, check_ping_for_experiment):
    xcodebuild.install()
    setup_experiment(load_branches)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testHomeScreenMessageDismissesCorrectly", erase=False
    )
    assert check_ping_for_experiment(reason="enrollment", branch=load_branches[0])

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
import time

import pytest


@pytest.mark.messaging_survey
def test_survey_navigates_correctly(xcodebuild, setup_experiment, start_app, experiment_branch, check_ping_for_experiment):
    xcodebuild.install(boot=False)
    setup_experiment()
    time.sleep(5)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", build=False,erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageNavigatesCorrectly", build=False, erase=False
    )
    # assert check_ping_for_experiment(reason="enrollment", branch=experiment_branch)

@pytest.mark.messaging_survey
def test_survey_no_thanks_navigates_correctly(xcodebuild, setup_experiment, start_app, experiment_branch, check_ping_for_experiment):
    xcodebuild.install(boot=False)
    setup_experiment()
    time.sleep(5)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", build=False, erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageNoThanksNavigatesCorrectly", build=False, erase=False
    )
    # assert check_ping_for_experiment(reason="enrollment", branch=experiment_branch)

@pytest.mark.messaging_survey
def test_survey_landscape_looks_correct(xcodebuild, setup_experiment, start_app, experiment_branch, check_ping_for_experiment):
    xcodebuild.install(boot=False)
    setup_experiment()
    time.sleep(5)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", build=False, erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageLandscapeUILooksCorrect", build=False, erase=False
    )
    # assert check_ping_for_experiment(reason="enrollment", branch=experiment_branch)

@pytest.mark.messaging_new_tab_card
def test_homescreen_survey_navigates_correctly(xcodebuild, setup_experiment, start_app, experiment_branch, check_ping_for_experiment):
    xcodebuild.install(boot=False)
    setup_experiment()
    time.sleep(5)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", build=False, erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testHomeScreenMessageNavigatesCorrectly", build=False, erase=False
    )
    # assert check_ping_for_experiment(reason="enrollment", branch=experiment_branch)

@pytest.mark.messaging_new_tab_card
def test_homescreen_survey_dismisses_correctly(xcodebuild, setup_experiment, start_app, experiment_branch, check_ping_for_experiment):
    xcodebuild.install(boot=False)
    setup_experiment()
    time.sleep(5)
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", build=False, erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testHomeScreenMessageDismissesCorrectly", build=False, erase=False
    )
    # assert check_ping_for_experiment(reason="enrollment", branch=experiment_branch)

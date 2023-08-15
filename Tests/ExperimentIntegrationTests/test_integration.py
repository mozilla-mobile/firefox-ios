def test_testing(xcodebuild, setup_experiment, start_app):
    xcodebuild.install()
    setup_experiment()
    xcodebuild.test("XCUITests/ExperimentIntegrationTests/testVerifyExperimentEnrolled", erase=False)
    start_app()
    xcodebuild.test(
        "XCUITests/ExperimentIntegrationTests/testMessageNavigatesCorrectly", erase=False
    )

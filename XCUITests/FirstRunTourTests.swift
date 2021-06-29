import XCTest


class FirstRunTourTests: BaseTestCase {

    override func setUp() {
        launchArguments = [LaunchArguments.ClearProfile]
        super.setUp()
    }

    // Smoketest
    func testFirstRunTour() {
        // Complet the First run from first screen to the latest one
        // Check that the first's tour screen is shown as well as all the elements in there
        waitForExistence(app.staticTexts["Welcome to Firefox"])
        XCTAssertTrue(app.buttons["nextOnboardingButton"].exists)
        XCTAssertTrue(app.buttons["signInOnboardingButton"].exists)
        XCTAssertTrue(app.buttons["signUpOnboardingButton"].exists)

        // Swipe to the second screen
        app.buttons.staticTexts["Next"].tap()
        XCTAssertTrue(app.buttons["startBrowsingButtonSyncView"].exists)
        XCTAssertTrue(app.buttons["signUpButtonSyncView"].exists)
    }

    private func goToNextScreen() {
        app.buttons["nextOnboardingButton"].tap()
    }

    private func tapStartBrowsingButton() {
        app.buttons["startBrowsingButtonSyncView"].tap()
        // User starts in HomePanelScreen with the default Top Sites
        let topSites = app.collectionViews.cells["TopSitesCell"]
        waitForExistence(topSites)
    }
    
    func testStartBrowsingFromSecondScreen() {
        navigator.goto(FirstRun)
        goToNextScreen()
        tapStartBrowsingButton()
    }
    
    func testShowTourFromSettings() {
        goToNextScreen()
        tapStartBrowsingButton()
        app.buttons["urlBar-cancel"].tap()
        navigator.goto(ShowTourInSettings)
        waitForExistence(app.staticTexts["Welcome to Firefox"])
    }
}

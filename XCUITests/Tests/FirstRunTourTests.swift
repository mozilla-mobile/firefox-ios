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

        Base.helper.waitForExistence(Base.app.staticTexts["Welcome to Firefox"])
        XCTAssertTrue(Base.app.buttons["nextOnboardingButton"].exists)
        XCTAssertTrue(Base.app.buttons["signInOnboardingButton"].exists)
        XCTAssertTrue(Base.app.buttons["signUpOnboardingButton"].exists)

        // Swipe to the second screen
        Base.app.buttons.staticTexts["Next"].tap()
        XCTAssertTrue(Base.app.buttons["startBrowsingOnboardingButton"].exists)
        XCTAssertTrue(Base.app.buttons["signInOnboardingButton"].exists)
        XCTAssertTrue(Base.app.buttons["signUpOnboardingButton"].exists)
    }

    private func goToNextScreen() {
        Base.app.buttons["nextOnboardingButton"].tap()
    }

    private func tapStartBrowsingButton() {
        Base.app.buttons["startBrowsingOnboardingButton"].tap()
        // User starts in HomePanelScreen with the default Top Sites
        let topSites = Base.app.collectionViews.cells["TopSitesCell"]
        Base.helper.waitForExistence(topSites)
    }
    
    func testStartBrowsingFromSecondScreen() {
        navigator.goto(FirstRun)
        goToNextScreen()
        tapStartBrowsingButton()
    }
    
    func testShowTourFromSettings() {
        goToNextScreen()
        tapStartBrowsingButton()
        navigator.goto(ShowTourInSettings)
        Base.helper.waitForExistence(Base.app.staticTexts["Welcome to Firefox"])
    }
}

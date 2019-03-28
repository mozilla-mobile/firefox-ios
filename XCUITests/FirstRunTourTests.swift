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
        waitForExistence(app.scrollViews["IntroViewController.scrollView"])
        waitForExistence(app.staticTexts["Thanks for choosing Firefox!"])
        XCTAssertFalse(app.buttons["IntroViewController.startBrowsingButton"].exists)
        XCTAssertTrue(app.images["tour-Welcome"].exists)
        XCTAssertTrue(app.pageIndicators["IntroViewController.pageControl"].exists)
        XCTAssertEqual(app.pageIndicators["IntroViewController.pageControl"].value as? String, "page 1 of 2")

        // Swipe to the second screen
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        waitForExistence(app.staticTexts["Pick up where you left off"])
        XCTAssertTrue(app.buttons["IntroViewController.startBrowsingButton"].exists)
        XCTAssertTrue(app.images["tour-Sync"].exists)
        XCTAssertTrue(app.buttons["Sign in to Firefox"].exists)
        XCTAssertEqual(app.pageIndicators["IntroViewController.pageControl"].value as? String, "page 2 of 2")
    }

    private func goToNextScreen(swipe: Int) {
        for _ in 1...swipe {
            app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        }
    }

    private func tapStartBrowsingButton() {
        waitForExistence(app.buttons["IntroViewController.startBrowsingButton"])
        app.buttons["IntroViewController.startBrowsingButton"].tap()
        // User starts in HomePanelScreen with the default Top Sites
        let topSites = app.collectionViews.cells["TopSitesCell"]
        waitForExistence(topSites)
    }
    
    func testStartBrowsingFromSecondScreen() {
        navigator.goto(FirstRun)
        goToNextScreen(swipe: 1)
        tapStartBrowsingButton()
    }
    
    func testShowTourFromSettings() {
        goToNextScreen(swipe: 1)
        tapStartBrowsingButton()
        navigator.goto(ShowTourInSettings)
        waitForExistence(app.scrollViews["IntroViewController.scrollView"])
        waitForExistence(app.staticTexts["Thanks for choosing Firefox!"])
    }
}

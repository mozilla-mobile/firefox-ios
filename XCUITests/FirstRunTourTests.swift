import XCTest


class FirstRunTourTests: BaseTestCase {

    override func setUp() {
        launchArguments = [LaunchArguments.ClearProfile]
        super.setUp()
    }

    func testFirstRunTour() {
        // Complet the First run from first screen to the latest one
        // Check that the first's tour screen is shown as well as all the elements in there
        waitforExistence(app.scrollViews["IntroViewController.scrollView"])
        waitforExistence(app.staticTexts["Thanks for choosing Firefox!"])
        XCTAssertFalse(app.buttons["IntroViewController.startBrowsingButton"].exists)
        XCTAssertTrue(app.images["tour-Welcome"].exists)
        XCTAssertTrue(app.pageIndicators["IntroViewController.pageControl"].exists)
        XCTAssertEqual(app.pageIndicators["IntroViewController.pageControl"].value as? String, "page 1 of 5")

        // Swipe to the second screen
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        waitforExistence(app.staticTexts["Your search, your way"])
        XCTAssertTrue(app.buttons["IntroViewController.startBrowsingButton"].exists)
        XCTAssertTrue(app.images["tour-Search"].exists)
        XCTAssertEqual(app.pageIndicators["IntroViewController.pageControl"].value as? String, "page 2 of 5")

        // Swipe to the third screen
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        waitforExistence(app.staticTexts["Browse like no one’s watching"])
        XCTAssertTrue(app.buttons["IntroViewController.startBrowsingButton"].exists)
        XCTAssertTrue(app.images["tour-Private"].exists)
        XCTAssertEqual(app.pageIndicators["IntroViewController.pageControl"].value as? String, "page 3 of 5")

        // Swipe to the fourth screen
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        waitforExistence(app.staticTexts["You’ve got mail… options"])
        XCTAssertTrue(app.buttons["IntroViewController.startBrowsingButton"].exists)
        XCTAssertTrue(app.images["tour-Mail"].exists)
        XCTAssertEqual(app.pageIndicators["IntroViewController.pageControl"].value as? String, "page 4 of 5")

        // Swipe to the fifth screen
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        waitforExistence(app.staticTexts["Pick up where you left off"])
        XCTAssertTrue(app.buttons["IntroViewController.startBrowsingButton"].exists)
        XCTAssertTrue(app.images["tour-Sync"].exists)
        XCTAssertTrue(app.buttons["Sign in to Firefox"].exists)
        XCTAssertEqual(app.pageIndicators["IntroViewController.pageControl"].value as? String, "page 5 of 5")
    }

    private func goToNextScreen(swipe: Int) {
        for _ in 1...swipe {
            app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        }
    }

    private func tapStartBrowsingButton() {
        waitforExistence(app.buttons["IntroViewController.startBrowsingButton"])
        app.buttons["IntroViewController.startBrowsingButton"].tap()
        // User starts in HomePanelScreen with the default Top Sites
        let topSites = app.collectionViews.cells["TopSitesCell"]
        waitforExistence(topSites)
    }

    func testStartBrowsingFromSecondScreen() {
        navigator.goto(FirstRun)
        goToNextScreen(swipe: 1)
        tapStartBrowsingButton()
    }

    func testStartBrowsingFromThirdScreen() {
        navigator.goto(FirstRun)
        goToNextScreen(swipe:2)
        tapStartBrowsingButton()
    }

    func testStartBrowsingFromFourthScreen() {
        navigator.goto(FirstRun)
        goToNextScreen(swipe:3)
        tapStartBrowsingButton()
    }

    func testStartBrowsingFromFifthScreen() {
        navigator.goto(FirstRun)
        goToNextScreen(swipe:4)
        tapStartBrowsingButton()
    }

    func testShowTourFromSettings() {
        goToNextScreen(swipe: 1)
        tapStartBrowsingButton()
        navigator.goto(ShowTourInSettings)
        waitforExistence(app.scrollViews["IntroViewController.scrollView"])
        waitforExistence(app.staticTexts["Thanks for choosing Firefox!"])
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

final class MicrosurveyTests: BaseTestCase {
    override func setUp() {
        launchArguments = [
            LaunchArguments.SkipIntro,
            LaunchArguments.ResetMicrosurveyExpirationCount
        ]
        super.setUp()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2776932
    func testURLBorderHiddenWhenMicrosurveyPromptShown() throws {
        guard !iPad() else {
            throw XCTSkip("Toolbar option not available for iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        generateTriggerForMicrosurvey()
        XCTAssertFalse(app.otherElements[AccessibilityIdentifiers.Toolbar.urlBarBorder].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton].exists)
        XCTAssertTrue(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].exists)
        app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].tap()
        XCTAssertFalse(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2776933
    func testCloseButtonDismissesMicrosurveyPrompt() {
        generateTriggerForMicrosurvey()
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton],
                app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo],
                app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton]
            ]
        )
        app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].waitAndTap()
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton])
        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo])
        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2776931
    func testShowMicrosurvey() {
        generateTriggerForMicrosurvey()
        let continueButton = app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton]
        continueButton.tap()

        waitForElementsToExist(
            [
                app.images[AccessibilityIdentifiers.Microsurvey.Survey.firefoxLogo],
                app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton]
            ]
        )
        let tablesQuery = app.scrollViews.otherElements.tables
        let firstOption = tablesQuery.cells.firstMatch
        firstOption.tap()
        mozWaitForElementToExist(firstOption)
        XCTAssertEqual(firstOption.label, "Very satisfied")
        mozWaitForValueContains(firstOption, value: "1 out of 6")

        let secondOption = tablesQuery.cells["Neutral"]
        mozWaitForElementToExist(secondOption)
        XCTAssertEqual(secondOption.label, "Neutral")
        mozWaitForValueContains(secondOption, value: "Unselected, 3 out of 6")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2776934
    func testCloseButtonDismissesSurveyAndPrompt() {
        generateTriggerForMicrosurvey()
        let continueButton = app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton]
        continueButton.waitAndTap()

        app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton].waitAndTap()

        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Survey.firefoxLogo])
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton])
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton])
        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo])
        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton])
    }

    private func generateTriggerForMicrosurvey() {
        let homepageToggleButtonIphone =
        app.buttons[AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.privateModeToggleButton]
        let homepageToggleButtonIpad = app.buttons[AccessibilityIdentifiers.Browser.TopTabs.privateModeButton]
        if !iPad() {
            homepageToggleButtonIphone.waitAndTap()
            mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.PrivateMode.Homepage.link])
        } else {
            homepageToggleButtonIpad.waitAndTap()
            mozWaitForElementToExist(app.collectionViews[AccessibilityIdentifiers.Browser.TopTabs.collectionView])
        }
        if !iPad() {
            homepageToggleButtonIphone.waitAndTap()
            mozWaitForElementToExist(app.collectionViews[AccessibilityIdentifiers.FirefoxHomepage.collectionView])
        } else {
            homepageToggleButtonIpad.waitAndTap()
            mozWaitForElementToExist(app.collectionViews[AccessibilityIdentifiers.Browser.TopTabs.collectionView])
        }
    }
}

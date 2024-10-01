// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class MicrosurveyTests: BaseTestCase {
    override func setUp() {
        launchArguments = [
            LaunchArguments.SkipIntro,
            LaunchArguments.ResetMicrosurveyExpirationCount
        ]
        super.setUp()
    }

    func testShowMicrosurveyPromptFromHomepageTrigger() {
        // Disabled due to issue in toggling between regular and private modes.
        // https://github.com/mozilla-mobile/firefox-ios/issues/22295
        // generateTriggerForMicrosurvey()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton])
        mozWaitForElementToExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton])
    }

    func testURLBorderHiddenWhenMicrosurveyPromptShown() throws {
        guard !iPad() else {
            throw XCTSkip("Toolbar option not available for iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        // Disabled due to issue in toggling between regular and private modes.
        // https://github.com/mozilla-mobile/firefox-ios/issues/22295
        // generateTriggerForMicrosurvey()
        XCTAssertFalse(app.otherElements[AccessibilityIdentifiers.Toolbar.urlBarBorder].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton].exists)
        XCTAssertTrue(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].exists)
        app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].tap()
        XCTAssertFalse(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].exists)
    }

    func testCloseButtonDismissesMicrosurveyPrompt() {
        // Disabled due to issue in toggling between regular and private modes.
        // https://github.com/mozilla-mobile/firefox-ios/issues/22295
        // generateTriggerForMicrosurvey()
        app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].tap()
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton])
        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo])
        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton])
    }

    func testShowMicrosurvey() {
        // Disabled due to issue in toggling between regular and private modes.
        // https://github.com/mozilla-mobile/firefox-ios/issues/22295
        // generateTriggerForMicrosurvey()
        let continueButton = app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton]
        continueButton.tap()

        mozWaitForElementToExist(app.images[AccessibilityIdentifiers.Microsurvey.Survey.firefoxLogo])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton])
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

    func testCloseButtonDismissesSurveyAndPrompt() {
        // Disabled due to issue in toggling between regular and private modes.
        // https://github.com/mozilla-mobile/firefox-ios/issues/22295
        // generateTriggerForMicrosurvey()
        let continueButton = app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton]
        continueButton.tap()

        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton])
        app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton].tap()

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
            mozWaitForElementToExist(homepageToggleButtonIphone)
            homepageToggleButtonIphone.tap()
            mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.PrivateMode.Homepage.link])
        } else {
            mozWaitForElementToExist(homepageToggleButtonIpad)
            homepageToggleButtonIpad.tap()
            mozWaitForElementToExist(app.collectionViews[AccessibilityIdentifiers.Browser.TopTabs.collectionView])
        }
        if !iPad() {
            homepageToggleButtonIphone.tap()
            mozWaitForElementToExist(app.collectionViews[AccessibilityIdentifiers.FirefoxHomepage.collectionView])
        } else {
            homepageToggleButtonIpad.tap()
            mozWaitForElementToExist(app.collectionViews[AccessibilityIdentifiers.Browser.TopTabs.collectionView])
        }
    }
}

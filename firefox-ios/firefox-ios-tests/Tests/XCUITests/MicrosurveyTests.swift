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
        generateTriggerForMicrosurvey()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton])
        mozWaitForElementToExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton])
    }

    func testCloseButtonDismissesMicrosurveyPrompt() {
        generateTriggerForMicrosurvey()
        app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].tap()
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton])
        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo])
        mozWaitForElementToNotExist(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton])
    }

    func testShowMicrosurvey() {
        generateTriggerForMicrosurvey()
        let continueButton = app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton]
        continueButton.tap()

        mozWaitForElementToExist(app.images[AccessibilityIdentifiers.Microsurvey.Survey.firefoxLogo])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton])
    }

    func testCloseButtonDismissesSurveyAndPrompt() {
        generateTriggerForMicrosurvey()
        let continueButton = app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton]
        continueButton.tap()

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
            homepageToggleButtonIphone.tap()
            mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.PrivateMode.Homepage.link])
        } else {
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

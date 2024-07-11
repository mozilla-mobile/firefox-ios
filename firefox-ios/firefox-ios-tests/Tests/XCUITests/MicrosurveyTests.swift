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
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton].exists)
        XCTAssertTrue(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].exists)
    }

    func testCloseButtonDismissesMicrosurveyPrompt() {
        generateTriggerForMicrosurvey()
        app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].tap()
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton].exists)
        XCTAssertFalse(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo].exists)
        XCTAssertFalse(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].exists)
    }

    func testShowMicrosurvey() {
        generateTriggerForMicrosurvey()
        let continueButton = app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton]
        continueButton.tap()

        XCTAssertTrue(app.images[AccessibilityIdentifiers.Microsurvey.Survey.firefoxLogo].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton].exists)
    }

    func testCloseButtonDismissesSurveyAndPrompt() {
        generateTriggerForMicrosurvey()
        let continueButton = app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton]
        continueButton.tap()

        app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton].tap()

        XCTAssertFalse(app.images[AccessibilityIdentifiers.Microsurvey.Survey.firefoxLogo].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Microsurvey.Survey.closeButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton].exists)
        XCTAssertFalse(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo].exists)
        XCTAssertFalse(app.images[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].exists)
    }

    private func generateTriggerForMicrosurvey() {
        let homepageToggleButton = app
            .collectionViews[AccessibilityIdentifiers.FirefoxHomepage.collectionView]
            .buttons[AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.privateModeToggleButton]
        homepageToggleButton.tap()
        let privateHomepageToggleButton = app
            .scrollViews
            .otherElements
            .buttons[AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.privateModeToggleButton]
        privateHomepageToggleButton.tap()
        mozWaitForElementToExist(app.collectionViews["FxCollectionView"])
    }
}

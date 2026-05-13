// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class MicrosurveyScreen {
    private let app: XCUIApplication
    private let sel: MicrosurveySelectorsSet

    init(app: XCUIApplication, selectors: MicrosurveySelectorsSet = MicrosurveySelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var promptFirefoxLogo: XCUIElement { sel.PROMPT_FIREFOX_LOGO.element(in: app) }
    private var promptCloseButton: XCUIElement { sel.PROMPT_CLOSE_BUTTON.element(in: app) }
    private var takeSurveyButton: XCUIElement { sel.TAKE_SURVEY_BUTTON.element(in: app) }
    private var surveyFirefoxLogo: XCUIElement { sel.SURVEY_FIREFOX_LOGO.element(in: app) }
    private var surveyCloseButton: XCUIElement { sel.SURVEY_CLOSE_BUTTON.element(in: app) }
    private var firstSurveyOption: XCUIElement { app.scrollViews.otherElements.tables.cells.firstMatch }
    private var topBorder: XCUIElement { sel.TOP_BORDER.element(in: app) }

    func tapTakeSurveyButton() {
        takeSurveyButton.waitAndTap()
    }

    func tapSurveyCloseButton() {
        surveyCloseButton.waitAndTap()
    }

    func tapPromptCloseButton() {
        promptCloseButton.waitAndTap()
    }

    func assertPromptExists() {
        BaseTestCase().waitForElementsToExist([
            takeSurveyButton,
            promptFirefoxLogo,
            promptCloseButton
        ])
    }

    func assertPromptDismissed() {
        BaseTestCase().mozWaitForElementToNotExist(takeSurveyButton)
        BaseTestCase().mozWaitForElementToNotExist(promptFirefoxLogo)
        BaseTestCase().mozWaitForElementToNotExist(promptCloseButton)
    }

    func assertSurveyExists() {
        BaseTestCase().waitForElementsToExist([
            surveyFirefoxLogo,
            surveyCloseButton
        ])
    }

    func assertSurveyDismissed() {
        BaseTestCase().mozWaitForElementToNotExist(surveyFirefoxLogo)
        BaseTestCase().mozWaitForElementToNotExist(surveyCloseButton)
    }

    func tapFirstSurveyOption() {
        firstSurveyOption.waitAndTap()
    }

    func assertFirstSurveyOptionSelected() {
        BaseTestCase().mozWaitForElementToExist(firstSurveyOption)
        XCTAssertEqual(firstSurveyOption.label, "Very satisfied")
        BaseTestCase().mozWaitForValueContains(firstSurveyOption, value: "1 out of 6")
    }

    func assertSurveyOptionUnselected(label: String) {
        let option = sel.surveyOption(label: label).element(in: app)
        BaseTestCase().mozWaitForElementToExist(option)
        XCTAssertEqual(option.label, label)
        BaseTestCase().mozWaitForValueContains(option, value: "Unselected, 3 out of 6")
    }

    func assertTopBorderHidden() {
        XCTAssertFalse(topBorder.exists)
    }

    func assertTopBorderVisible() {
        XCTAssertTrue(topBorder.exists)
    }
}

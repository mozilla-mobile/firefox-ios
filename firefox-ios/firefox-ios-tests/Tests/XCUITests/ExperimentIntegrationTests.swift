// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class ExperimentIntegrationTests: BaseTestCase {
    var secretMenu = false
    var experimentName = ProcessInfo.processInfo.environment["EXPERIMENT_NAME"] ?? "None"

    override func setUpApp() {
        app.activate()
        let closeButton = app.buttons["CloseButton"]
        if closeButton.waitForExistence(timeout: TIMEOUT) {
            closeButton.waitAndTap()
        }
        super.setUpScreenGraph()
        UIView.setAnimationsEnabled(false) // IMPORTANT
    }

    func enableSecretMenu() {
        let element = app.tables.cells.containing(
            NSPredicate(format: "identifier CONTAINS 'FxVersion'")
        )
        for _ in 0...5 {
            element.element.waitAndTap()
        }
        secretMenu = true
    }

    func checkExperimentEnrollment(experimentName: String) -> Bool {
        navigator.goto(SettingsScreen)

        if !secretMenu {
            enableSecretMenu()
        }
        let experiments = app.tables.cells.containing(NSPredicate(format: "label CONTAINS 'Experiments'"))
        experiments.element.waitAndTap()

        let experiment = app.tables.cells.containing(NSPredicate(format: "label CONTAINS '\(experimentName)'"))
        XCTAssertNotNil(experiment)

        experiment.element.waitAndTap()

        let checkmark = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'checkmark'")
        )
        if checkmark.element.exists {
            return true
        } else {
            return false
        }
    }
    func testVerifyExperimentEnrolled() throws {
        navigator.goto(SettingsScreen)

        // enable experiments secret menu
        enableSecretMenu()

        // match json experiment name
        XCTAssertTrue(checkExperimentEnrollment(experimentName: experimentName))
    }

    func testMessageNavigatesCorrectly() throws {
        let surveyLink = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'takeSurveyButton'")
        )

        wait(forElement: surveyLink.element, timeout: TIMEOUT_LONG)
        surveyLink.element.waitAndTap()
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "survey")
    }

    func testMessageNoThanksNavigatesCorrectly() throws {
        let dismissLink = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'dismissSurveyButton'")
        )

        wait(forElement: dismissLink.element, timeout: TIMEOUT_LONG)
        dismissLink.element.waitAndTap()

        navigator.goto(NewTabScreen)
        waitForTabsButton()

        let tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("1", tabsOpen as? String)
    }

    func testMessageLandscapeUILooksCorrect() throws {
        XCUIDevice.shared.orientation = .landscapeLeft

        let surveyLink = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'takeSurveyButton'")
        )
        app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'dismissSurveyButton'")
        )

        wait(forElement: surveyLink.element, timeout: TIMEOUT_LONG)
        surveyLink.element.waitAndTap()
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "survey")
    }

    func testHomeScreenMessageNavigatesCorrectly() throws {
        let surveyLink = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'HomeTabBanner.goToSettingsButton'")
        )

        wait(forElement: surveyLink.element, timeout: TIMEOUT_LONG)
        surveyLink.element.waitAndTap()
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "survey")
    }

    func testHomeScreenMessageDismissesCorrectly() throws {
        let surveyLink = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Close'")
        )

        wait(forElement: surveyLink.element, timeout: TIMEOUT_LONG)
        surveyLink.element.waitAndTap()

        navigator.goto(NewTabScreen)
        waitForTabsButton()

        let tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("1", tabsOpen as? String)
    }

    func testStudiesToggleDisablesExperiment() {
        navigator.goto(SettingsScreen)
        let studiesToggle = app.switches.matching(
            NSPredicate(format: "identifier CONTAINS 'settings.studiesToggle'")
        )
        wait(forElement: studiesToggle.element, timeout: TIMEOUT)
        XCTAssertEqual(studiesToggle.element.value as? String, "1")
        studiesToggle.element.waitAndTap()
        XCTAssertEqual(studiesToggle.element.value as? String, "0")
        XCTAssertFalse(checkExperimentEnrollment(experimentName: experimentName))
    }
}

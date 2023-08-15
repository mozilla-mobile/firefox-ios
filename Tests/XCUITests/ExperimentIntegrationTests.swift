// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class ExperimentIntegrationTests: BaseTestCase {
    override func setUpApp() {
        app.activate()
        let closeButton = app.buttons["bottomSheet close"]
        if closeButton.exists {
            closeButton.tap()
        }
        super.setUpScreenGraph()
    }

    func testVerifyExperimentEnrolled() throws {
        let toolbarClose = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Close'"))

        wait(forElement: toolbarClose.element, timeout: 15)
        toolbarClose.element(boundBy: 0).tap()
        navigator.goto(SettingsScreen)

        // enable experiments secret menu
        let element = app.tables.cells.containing(
            NSPredicate(format: "identifier CONTAINS 'FxVersion'")
        )
        for _ in 0...5 {
            element.element.tap()
        }

        // open experiments menu
        let experiments = app.tables.cells.containing(NSPredicate(format: "label CONTAINS 'Experiments'"))
        experiments.element.tap()

        // match json experiment name
        let experiment = app.tables.cells.containing(NSPredicate(format: "label CONTAINS 'Viewpoint'"))
        XCTAssertNotNil(experiment)
    }

    func testMessageNavigatesCorrectly() throws {
        let surveyLink = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'takeSurveyButton'")
        )

        wait(forElement: surveyLink.element, timeout: 15)
        surveyLink.element.tap()
        waitForValueContains(app.textFields["url"], value: "survey")
    }
}

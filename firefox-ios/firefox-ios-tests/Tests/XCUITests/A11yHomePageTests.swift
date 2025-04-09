// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class A11yHomePageTests: BaseTestCase {
    func testA11yHomePageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }

        try app.performAccessibilityAudit()
    }

    func testA11yHomePageAccessibilityLabels() throws {
        let sanitizedTestName = self.name.replacingOccurrences(of: "()", with: "").replacingOccurrences(of: ".", with: "_")
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        guard #available(iOS 17.0, *), !skipPlatform else { return }

        A11yUtils.checkMissingLabels(
            in: app.buttons.allElementsBoundByIndex,
            screenName: "Home Page",
            missingLabels: &missingLabels,
            elementType: "Button"
        )

        A11yUtils.checkMissingLabels(
            in: app.images.allElementsBoundByIndex,
            screenName: "Home Page",
            missingLabels: &missingLabels,
            elementType: "Image"
        )

        A11yUtils.checkMissingLabels(
            in: app.staticTexts.allElementsBoundByIndex,
            screenName: "Home Page",
            missingLabels: &missingLabels,
            elementType: "Static Text"
        )

        // Generate Report
        A11yUtils.generateAndAttachReport(missingLabels: missingLabels, testName: sanitizedTestName, generateCsv: false)
    }
}

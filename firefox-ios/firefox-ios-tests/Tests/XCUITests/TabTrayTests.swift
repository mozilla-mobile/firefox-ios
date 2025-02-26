// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class TabTrayTests: BaseTestCase {
    func testAccessibility() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }

        waitForTabsButton()
        waitUntilPageLoad()

        // Open Tab Tray
        navigator.goto(TabTray)

        try app.performAccessibilityAudit { issue in
            var shouldIgnore = false

            // ignore text clipped issue for the tab cell title
            if let element = issue.element,
               element.elementType == .staticText,
               element.label.contains("Homepage"),
               issue.auditType == .textClipped {
                shouldIgnore = true
            }
            return shouldIgnore
        }
    }
}

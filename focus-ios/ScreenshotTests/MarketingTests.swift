/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class MarketingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func test01Settings() {
        let app = XCUIApplication()

        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared().orientation = .landscapeLeft
        }

        app.buttons["FirstRunViewController.button"].tap()
        app.buttons["HomeView.settingsButton"].tap()
        snapshot("01Settings")
    }
}

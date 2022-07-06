// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let NoImageButtonIdentifier = ImageIdentifiers.noImageMode
let ContextMenuIdentifier = "Context Menu"

class NoImageTests: BaseTestCase {

    private func checkShowImages() {
        waitForExistence(app.tables.cells[NoImageButtonIdentifier])
        XCTAssertTrue(app.tables.cells[NoImageButtonIdentifier].images["enabled"].exists)
    }

    private func checkHideImages() {
        waitForExistence(app.tables.cells[NoImageButtonIdentifier])
        XCTAssertTrue(app.tables.cells[NoImageButtonIdentifier].images["disabled"].exists)
    }

    // Functionality is tested by UITests/NoImageModeTests, here only the UI is updated properly
    // Since it is tested in UI let's disable. Keeping here just in case it needs to be re-enabled
    func testImageOnOff() {
        // Go to a webpage, and select no images or hide images, check it's hidden or not
        navigator.openNewURL(urlString: "www.google.com")
        waitUntilPageLoad()

        // Select hide images, and check the UI is updated
        navigator.performAction(Action.ToggleNoImageMode)
        checkShowImages()

        // Select show images, and check the UI is updated
        navigator.performAction(Action.ToggleNoImageMode)
        checkHideImages()
    }
}

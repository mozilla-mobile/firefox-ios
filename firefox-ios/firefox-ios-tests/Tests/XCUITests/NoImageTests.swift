// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class NoImageTests: BaseTestCase {
    private func checkShowImages(showImages: Bool = true) {
        let noImageStatusMode = app.otherElements.tables.cells.switches["NoImageModeStatus"]
        mozWaitForElementToExist(noImageStatusMode)
        if showImages {
            XCTAssertEqual(noImageStatusMode.value as? String, "0")
        } else {
            XCTAssertEqual(noImageStatusMode.value as? String, "1")
        }
    }

    // Functionality is tested by UITests/NoImageModeTests, here only the UI is updated properly
    // Since it is tested in UI let's disable. Keeping here just in case it needs to be re-enabled
    func testImageOnOff() {
        // Select no images or hide images, check it's hidden or not
        waitUntilPageLoad()

        // Select hide images
        let blockImagesSwitch = app.otherElements
            .tables.cells.switches[AccessibilityIdentifiers.Settings.BlockImages.title]
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        mozWaitForElementToExist(blockImagesSwitch)
        navigator.performAction(Action.ToggleNoImageMode)
        checkShowImages(showImages: false)

        // Select show images
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        mozWaitForElementToExist(blockImagesSwitch)
        navigator.performAction(Action.ToggleNoImageMode)
        checkShowImages(showImages: true)
    }
}

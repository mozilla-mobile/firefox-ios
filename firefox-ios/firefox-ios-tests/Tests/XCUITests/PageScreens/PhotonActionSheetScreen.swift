// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class PhotonActionSheetScreen {
    private let app: XCUIApplication
    private let sel: PhotonActionSheetSelectorsSet

    init(app: XCUIApplication, selectors: PhotonActionSheetSelectorsSet = PhotonActionSheetSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertPhotonActionSheetExists(timeout: TimeInterval = TIMEOUT) {
        if #unavailable(iOS 16) {
            BaseTestCase().waitForElementsToExist(
                [
                    app.otherElements["ActivityListView"].navigationBars["UIActivityContentView"],
                    app.buttons["Copy"]
                ]
            )
        } else {
            BaseTestCase().waitForElementsToExist(
                [
                app.otherElements["ActivityListView"].otherElements["Example Domain"],
                app.otherElements["ActivityListView"].otherElements["example.com"],
                app.collectionViews.cells["Copy"]
                ]
            )
        }
    }

    func tapFennecIcon() {
        var fennecElement = app.collectionViews.scrollViews.cells.elementContainingText("Fennec")
        // This is not ideal but only way to get the element on iPhone 8
        // for iPhone 11, that would be boundBy: 2
        if #unavailable(iOS 17) {
            fennecElement = app.collectionViews.scrollViews.cells
                .matching(identifier: "XCElementSnapshotPrivilegedValuePlaceholder").element(boundBy: 1)
        }
        fennecElement.waitAndTap()
    }

    func assertShareViewExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(app.navigationBars["ShareTo.ShareView"])

        BaseTestCase().waitForElementsToExist(
            [
                app.staticTexts["Open in Firefox"],
                app.staticTexts["Load in Background"],
                app.staticTexts["Bookmark This Page"],
                app.staticTexts["Add to Reading List"],
                app.staticTexts["Send to Device"]
            ]
        )
    }
}

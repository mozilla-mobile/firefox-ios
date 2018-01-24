/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let webpage = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]

class HistoryTests: BaseTestCase {
    func testEmptyHistoryListFirstTime() {
        // Go to History List from Top Sites and check it is empty
        navigator.goto(HomePanel_History)
        waitforExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertTrue(app.tables.cells["HistoryPanel.recentlyClosedCell"].exists)
        XCTAssertTrue(app.tables.cells["HistoryPanel.syncedDevicesCell"].exists)
        XCTAssertFalse(app.tables.otherElements.staticTexts["Today"].exists)
    }

    func testOpenHistoryFromBrowserContextMenuOptions() {
        navigator.openURL(webpage["url"]!)
        navigator.browserPerformAction(.openHistoryOption)

        // Go to History List from Browser context menu and there should be one entry
        waitforExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertTrue(app.tables.otherElements.staticTexts["Today"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts[webpage["label"]!].exists)
    }

    func testOpenSyncDevices() {
        navigator.goto(HomePanel_History)
        app.tables.cells["HistoryPanel.syncedDevicesCell"].tap()
        waitforExistence(app.tables.cells.staticTexts["Firefox Sync"])
        XCTAssertTrue(app.tables/*@START_MENU_TOKEN@*/.buttons["Sign in"]/*[[".cells.buttons[\"Sign in\"]",".buttons[\"Sign in\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.exists)
    }

    func testClearHistoryFromSettings() {
        // Browse to have an item in history list
        navigator.openURL(webpage["url"]!)
        navigator.goto(HomePanel_History)
        waitforExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertTrue(app.tables.cells.staticTexts[webpage["label"]!].exists)

        // Go to Clear Data
        navigator.performAction(Action.AcceptClearPrivateData)

        // Back on History panel view check that there is not any item
        navigator.goto(HomePanel_History)
        waitforExistence(app.tables.cells["HistoryPanel.recentlyClosedCell"])
        XCTAssertFalse(app.tables.cells.staticTexts[webpage["label"]!].exists)
    }
}

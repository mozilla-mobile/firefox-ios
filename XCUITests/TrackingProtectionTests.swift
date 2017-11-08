/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TrackingProtectionTests: BaseTestCase {
    // This test is to change the tracking protection to block known blockers
    func testTrackingProtection() {
        navigator.goto(SettingsScreen)
        let appSettingsTableView = app.tables["AppSettingsTableViewController.tableView"]
        //Scroll the table view until Tracking Proection cell is visible
        while !app.staticTexts["Tracking Protection"].exists {
            appSettingsTableView.swipeUp()
        }
        appSettingsTableView.staticTexts["Tracking Protection"].tap()

        //Check "Private Browsing Mode Only" is selected and other items are not selected
        XCTAssertFalse(app.tables.cells["Always On"].isSelected)
        XCTAssertTrue(app.tables.cells["Private Browsing Mode Only"].isSelected)
        XCTAssertFalse(app.tables.cells["Never"].isSelected)

        //Select "Always On"
        app.tables.cells["Always On"].tap()
        XCTAssertTrue(app.tables.cells["Always On"].isSelected)

        app.navigationBars["Tracking Protection"].buttons["Settings"].tap()

        waitforExistence(app.navigationBars["Settings"].buttons["Done"])
        app.navigationBars["Settings"]/*@START_MENU_TOKEN@*/.buttons["Done"]/*[[".buttons[\"Done\"]",".buttons[\"AppSettingsTableViewController.navigationItem.leftBarButtonItem\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.tap()

        app/*@START_MENU_TOKEN@*/.buttons["TabToolbar.menuButton"]/*[[".buttons[\"Menu\"]",".buttons[\"TabToolbar.menuButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        let settingsmenuitemCell = app.tables.cells["Settings"]
        settingsmenuitemCell.tap()

        let appSettingsTableView1 = app.tables["AppSettingsTableViewController.tableView"]
        //Scroll the table view until Tracking Proection cell is visible
        while !app.staticTexts["Tracking Protection"].exists {
            appSettingsTableView1.swipeUp()
        }

        appSettingsTableView1.staticTexts["Tracking Protection"].tap()
        waitforExistence(app.tables.cells["Always On"])

        //Check "Always On" is selected and other items are not selected
        XCTAssertTrue(app.tables.cells["Always On"].isSelected)
        XCTAssertFalse(app.tables.cells["Private Browsing Mode Only"].isSelected)
        XCTAssertFalse(app.tables.cells["Never"].isSelected)
    }
}

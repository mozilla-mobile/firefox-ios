/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class MailAppSettingsTests: BaseTestCase {
    func testOpenMailAppSettings() {
        navigator.goto(OpenWithSettings)

        // Check that the list is shown
        Base.helper.waitForExistence(Base.app.tables["OpenWithPage.Setting.Options"])
        XCTAssertTrue(Base.app.tables["OpenWithPage.Setting.Options"].exists)

        // Check that the list is shown with all elements disabled
        XCTAssertTrue(Base.app.tables.staticTexts["OPEN MAIL LINKS WITH"].exists)
        XCTAssertFalse(Base.app.tables.cells.staticTexts["Mail"].isSelected)
        XCTAssertFalse(Base.app.tables.cells.staticTexts["Outlook"].isSelected)
        XCTAssertFalse(Base.app.tables.cells.staticTexts["Airmail"].isSelected)
        XCTAssertFalse(Base.app.tables.cells.staticTexts["Mail.Ru"].isSelected)
        XCTAssertFalse(Base.app.tables.cells.staticTexts["myMail"].isSelected)
        XCTAssertFalse(Base.app.tables.cells.staticTexts["Spark"].isSelected)
        XCTAssertFalse(Base.app.tables.cells.staticTexts["YMail!"].isSelected)
        XCTAssertFalse(Base.app.tables.cells.staticTexts["Gmail"].isSelected)

        // Check that tapping on an element does nothing
        Base.helper.waitForExistence(Base.app.tables["OpenWithPage.Setting.Options"])
        Base.app.tables.cells.staticTexts["Airmail"].tap()
        XCTAssertFalse(Base.app.tables.cells.staticTexts["Airmail"].isSelected)

        // Check that user can go back from that setting
        navigator.goto(HomePanelsScreen)
    }
}

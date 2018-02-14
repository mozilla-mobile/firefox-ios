/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DatabaseFixtureTest: BaseTestCase {
    func testDatabaseFixture() {
        let file = "testDatabaseFixture-browser.db"
        let arg = LaunchArguments.LoadDatabasePrefix + file
        app.terminate()
        restart(app, args: [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, arg])

        // app will now start with prepopulated database
        navigator.nowAt(HomePanelsScreen)
        waitforExistence(app.collectionViews.cells["TopSitesCell"])
        navigator.browserPerformAction(.openBookMarksOption)
        waitforExistence(app.tables["Bookmarks List"])
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
    }
}

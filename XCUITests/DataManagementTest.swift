/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DataManagementTest: BaseTestCase {
    func testCheckDataManagementSettingsByDefault() {
        navigator.goto(WebsiteDataSettings)
  //    XCTAssertEqual(app.tables.cells.count, 0)
        waitforExistence(app.navigationBars["Website Data"])
      navigator.performAction(Action.SearchWebsites)
    }


//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }


}

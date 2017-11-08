/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class HomePageSettingsTest: BaseTestCase {
    // This test has moved from KIF UITest - accesses google.com instead of local webserver instance
    func testCurrentPage() {
        navigator.goto(BrowserTab)

        // Accessing https means that it is routed
        var currentURL = app.textFields["url"].value as! String

        // Go via the menu, becuase if we go via the TabTray, then we
        // won't have a current tab.
        navigator.goto(HomePageSettings)
        app.tables.staticTexts["Use Current Page"].tap()

        // check the value of the current homepage
        let homepageURL = app.tables.textFields["HomePageSettingTextField"].value as? String

        if homepageURL?.hasPrefix("https://") == true {
            currentURL = "https://\(currentURL)"
        }
        XCTAssertEqual(currentURL, homepageURL)
        app.tables.staticTexts["Clear"].tap()

        let urlString = app.tables.textFields["HomePageSettingTextField"].value ?? ""

        if iPad() {
            XCTAssertEqual("", urlString as! String)
        } else {
            XCTAssertEqual("Enter a webpage", urlString as! String)
        }
    }

    /* Disabled due to new Photon UI
    // Check whether the toolbar/menu shows homepage icon
    func testShowHomePageIcon() {
        // Check the Homepage icon is present in menu by default
        navigator.goto(BrowserTab)
        var currentURL = app.textFields["url"].value as! String
        navigator.goto(PageOptionsMenu)
        waitforExistence(app.tables.staticTexts["Set as Homepage"])
        app.tables.staticTexts["Set as Homepage"].tap()
        app.buttons["Set Homepage"].tap()

        navigator.nowAt(BrowserTab)
        navigator.goto(HomePageSettings)

        if currentURL.hasPrefix("https://") == false {
            currentURL = "https://\(currentURL)"
        }

        // Go to settings, and check the url are matching or not
        let value = app.textFields["HomePageSettingTextField"].value as! String
        XCTAssertEqual(value, currentURL,
                       "The webpage typed does not match with the one saved")
    }
     */
}

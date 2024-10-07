// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// NOTE: This test should be DISABLED on XCUITEST/UITEST scheme. This test should be run in conjunction with
// XCode Profiler to measure the memory/CPU load
class SiteLoadTest: BaseTestCase {
    func testLoadSite() {
        let site = ["http://www.forbes.com", "http://www.amazon.com", "http://theguardian.com", "http://www.reddit.com", "http://cnn.com"]
        let durationInHrs = 1
        let futureDate = Date().addingTimeInterval(TimeInterval(60 * 60 * durationInHrs))
        var counter = 0
        while Date() < futureDate {
            navigator.goto(URLBarOpen)
            navigator.openURL(site[counter % 5])
            sleep(5)

            navigator.nowAt(BrowserTab)
            navigator.goto(TabTray)

            navigator.performAction(Action.AcceptRemovingAllTabs)
            navigator.goto(BrowserTab)
            mozWaitForElementToNotExist(app.staticTexts["1 tab(s) closed"])

            // clear the cache
            navigator.goto(ClearPrivateDataSettings)
            app.tables.staticTexts["Clear Private Data"].tap()
            mozWaitForElementToExist(app.alerts.buttons["OK"])
            app.alerts.buttons["OK"].tap()
            navigator.goto(BrowserTab)
            mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url])
            counter += 1
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import Foundation
import Shared

class DatabaseFixtureTest: BaseTestCase {

    let fixtures = ["testOneBookmark": "testDatabaseFixture-browser.db", "testHistoryDatabaseFixture": "testHistoryDatabase4000-browser.db", "testLoadNumberOfSites": "testDatabaseFixture-browser.db"]

    let sitesList = top5000SitesList.top5000

    let dbSizes : [Int]  = [2, 5]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name!.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        // for the current test name, add the db fixture used
        launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.LoadDatabasePrefix + fixtures[key]!]
        super.setUp()
    }

    func testOneBookmark() {
        navigator.browserPerformAction(.openBookMarksOption)
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
    }

    func testHistoryDatabaseFixture() {
        navigator.goto(HomePanel_History)

        // History list has two cells that are for recently closed and synced devices that should not count as history items,
        // the actual max number is 100
        let loaded = NSPredicate(format: "count == 102")
        expectation(for: loaded, evaluatedWith: app.tables["History List"].cells, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }

    // This two tests should be disabled. They are only meant to generate the browserDB or check how all web sites are presented
    /*func testLoadAllSites() {
        for index in sitesList.top5000SitesList.indices {
            navigator.openURL(sitesList.top5000SitesList[index])
        }
    }*/

    func testLoadNumberOfSites() {
        for i in dbSizes {
        // For example to navigate to the n first top sites. This can be changed as per needs
            print("numero \(i)")
            loadNumberOfWebPages(numberWebPages: i)
            saveDB(numberWebPages: i)
        }
    }

    private func loadNumberOfWebPages (numberWebPages: Int) {
        let sitesListSlice = sitesList.prefix(numberWebPages)

        for index in sitesListSlice.indices {
            navigator.openURL(sitesListSlice[index])
            waitUntilPageLoad()
        }
    }

    private func saveDB(numberWebPages: Int) {
        let dbPath = "/Users/irios/Library/Developer/CoreSimulator/Devices/50819458-7D3F-45B1-928C-D9E3535775BB/data/Containers/Shared/AppGroup/DF67151D-E832-41E2-B926-6B54B7D390B8/profile.testProfile/browser.db"

        //let dbPathPart = "/Users/irios/Library/Developer/CoreSimulator/Devices/CC3FFB15-173A-4D22-8734-7A234B4692D9/data/Containers/Shared/AppGroup"
        let documents = URL(fileURLWithPath: dbPath)
        let output = "/Users/irios/Documents/test/\(numberWebPages).db"
        //let output = "/Users/irios/Documents/test/1.db"
        let outputDir = URL(fileURLWithPath: output)
        try! FileManager.default.copyItem(at: documents, to: outputDir)

    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class CreateDBTest: BaseTestCase {
    // These tests should be disabled. They are only meant to generate the browserDB or check how all web sites are presented

    let sitesList = top5000SitesList.top5000
    // Here the size of the desired DBs can be set
    let dbSizes : [Int]  = [1, 2, 10]

    var firstEntry = 0
    var lastEntry = 0

    func testLoadAllSites() {
        // This test will browse all web pages in the list
        for index in sitesList.indices {
            navigator.openURL(sitesList[index])
            waitUntilPageLoad()
        }
    }

    func testLoadNumberOfSites() {
        // A DB is created for each size in dbSizes, each DB start from the first web site on the list
        for dbEntries in dbSizes {
            loadNumberOfWebPages(numberWebPages: dbEntries)
            saveDB(numberWebPages: dbEntries)
            clearDataBase()
        }
    }

    func testLoadNumberOfSitesStartingFromLastVisitedWebSite() {
        // A DB with the indicated size is created starting from the latest visited web sited
        for dbEntries in dbSizes {
            let lastItemInArrayToSelect = sitesList.prefix(dbEntries+lastEntry)
            let sitesListSlice = sitesList[firstEntry..<lastItemInArrayToSelect.count]

            for index in sitesListSlice.indices {
                navigator.openURL(sitesListSlice[index])
                waitUntilPageLoad()
                firstEntry += 1
            }
            lastEntry += dbEntries
            saveDB(numberWebPages: dbEntries)
            clearDataBase()
        }
    }

    func testLoadIncrementalNumberOfSites() {
        // DBs are created incrementaly from the previous DB adding the new visited websites
        for dbEntries in dbSizes {
            let lastItemInArrayToSelect = sitesList.prefix(dbEntries+lastEntry)
            let sitesListSlice = sitesList[firstEntry..<lastItemInArrayToSelect.count]

            for index in sitesListSlice.indices {
                navigator.openURL(sitesListSlice[index])
                waitUntilPageLoad()
                firstEntry += 1
            }
            lastEntry += dbEntries
            saveDB(numberWebPages: lastEntry)
        }
        clearDataBase()
    }

    private func loadNumberOfWebPages (numberWebPages: Int) {
        let sitesListSlice = sitesList.prefix(numberWebPages)

        for webPage in sitesListSlice.indices {
            navigator.openURL(sitesListSlice[webPage])
            waitUntilPageLoad()
        }
    }

    private func saveDB(numberWebPages: Int) {
        // Path where DB can be found
        let dbPath = "~/Library/Developer/CoreSimulator/Devices/<DeviceID>/data/Containers/Shared/AppGroup/<AppGroupID>/profile.profile/browser.db"
        let dbPathInput = URL(fileURLWithPath: dbPath)
        // Choose a path to store the generated DB
        let dbPathOutput = "/ChoosePath/\(numberWebPages).db"
        let dbPathOutputDir = URL(fileURLWithPath: dbPathOutput)
        try! FileManager.default.copyItem(at: dbPathInput, to: dbPathOutputDir)
    }

    private func clearDataBase() {
        // This is necessary so that in each DB the data accurate with each test
        navigator.performAction(Action.AcceptClearPrivateData)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@testable import Storage

import XCTest

class TestSQLitePinnedSites: XCTestCase {
    let files = MockFiles()

    fileprivate func deleteDatabases() {
        do {
            try files.remove("browser.db")
        } catch {}
    }

    override func tearDown() {
        super.tearDown()
        self.deleteDatabases()
    }

    override func setUp() {
        super.setUp()

        // Just in case tearDown didn't run or succeed last time!
        self.deleteDatabases()
    }

    func testPinnedTopSites() {
        let database = BrowserDB(filename: "testPinnedTopSites.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let pinnedSites = BrowserDBSQLite(database: database, prefs: prefs)

        // add 2 sites to pinned topsite
        // get pinned site and make sure it exists in the right order
        // remove pinned sites
        // make sure pinned sites dont exist

        // create pinned sites.
        let site1 = Site.createBasicSite(url: "http://s\(1)ite\(1).com/foo", title: "A \(1)")
        let site2 = Site.createBasicSite(url: "http://s\(2)ite\(2).com/foo", title: "A \(2)")

        let expectation = self.expectation(description: "First.")
        let done: @Sendable () -> Success = {
            expectation.fulfill()
            return succeed()
        }

        let addPinnedSites: @Sendable () -> Success = {
            return pinnedSites.addPinnedTopSite(site1) >>== {
                sleep(1) // Sleep to prevent intermittent issue with sorting on the timestamp
                return pinnedSites.addPinnedTopSite(site2)
            }
        }

        let checkPinnedSites: @Sendable () -> Success = {
            return pinnedSites.getPinnedTopSites() >>== { pinnedSites in
                XCTAssertEqual(pinnedSites.count, 2)
                XCTAssertEqual(pinnedSites[0]?.url, site2.url)
                XCTAssertEqual(pinnedSites[1]?.url, site1.url, "The older pinned site should be last")
                return succeed()
            }
        }

        let removePinnedSites: @Sendable () -> Success = {
            return pinnedSites.removeFromPinnedTopSites(site2) >>== {
                return pinnedSites.getPinnedTopSites() >>== { pinnedSites in
                    XCTAssertEqual(pinnedSites.count, 1, "There should only be one pinned site")
                    XCTAssertEqual(pinnedSites[0]?.url, site1.url, "Site1 should be the only pin left")
                    return succeed()
                }
            }
        }

        let dupePinnedSite: @Sendable () -> Success = {
            return pinnedSites.addPinnedTopSite(site1) >>== {
                return pinnedSites.getPinnedTopSites() >>== { pinnedSites in
                    XCTAssertEqual(pinnedSites.count, 1, "There should not be a dupe")
                    XCTAssertEqual(pinnedSites[0]?.url, site1.url, "Site1 should still be the only pin")
                    return succeed()
                }
            }
        }

        addPinnedSites()
            >>> checkPinnedSites
            >>> removePinnedSites
            >>> dupePinnedSite
            >>> done

        waitForExpectations(timeout: 3) { error in
            return
        }
    }

    func testPinnedTopSitesDuplicateDomains() {
        let database = BrowserDB(
            filename: "testPinnedTopSitesDuplicateDomains.db",
            schema: BrowserSchema(),
            files: files
        )
        let prefs = MockProfilePrefs()
        let pinnedSites = BrowserDBSQLite(database: database, prefs: prefs)

        // create pinned sites with a same domain name
        let site1 = Site.createBasicSite(url: "http://site.com/foo1", title: "A duplicate domain \(1)")
        let site2 = Site.createBasicSite(url: "http://site.com/foo2", title: "A duplicate domain \(2)")

        let expectation = self.expectation(description: "First.")
        let done: @Sendable () -> Success = {
            expectation.fulfill()
            return succeed()
        }

        let addPinnedSites: @Sendable () -> Success = {
            return pinnedSites.addPinnedTopSite(site1) >>== {
                sleep(1) // Sleep to prevent intermittent issue with sorting on the timestamp
                return pinnedSites.addPinnedTopSite(site2)
            }
        }

        let checkPinnedSites: @Sendable () -> Success = {
            return pinnedSites.getPinnedTopSites() >>== { pinnedSites in
                XCTAssertEqual(pinnedSites.count, 2)
                XCTAssertEqual(pinnedSites[0]?.url, site2.url)
                XCTAssertEqual(pinnedSites[1]?.url, site1.url, "The older pinned site should be last")
                return succeed()
            }
        }

        let removePinnedSites: @Sendable () -> Success = {
            return pinnedSites.removeFromPinnedTopSites(site2) >>== {
                return pinnedSites.getPinnedTopSites() >>== { pinnedSites in
                    XCTAssertEqual(pinnedSites.count, 0, "Duplicate pinned domains are removed with a fuzzy search")
                    return succeed()
                }
            }
        }

        addPinnedSites()
            >>> checkPinnedSites
            >>> checkPinnedSites
            >>> removePinnedSites
            >>> done

        waitForExpectations(timeout: 3) { error in
            return
        }
    }

    func testPinnedTopSites_idOfMaxSizeInt64() {
        let database = BrowserDB(
            filename: "testPinnedTopSitesDuplicateDomains.db",
            schema: BrowserSchema(),
            files: files
        )
        let prefs = MockProfilePrefs()
        let pinnedSites = BrowserDBSQLite(database: database, prefs: prefs)

        // create pinned sites with a same domain name
        let site = Site.createPinnedSite(
            url: "http://site.com/foo1",
            title: "A domain",
            isGooglePinnedTile: false
        )

        let expectation = self.expectation(description: "Add site")
        let done: @Sendable () -> Success = {
            expectation.fulfill()
            return succeed()
        }

        let addPinnedSite: @Sendable () -> Success = {
            return pinnedSites.addPinnedTopSite(site)
        }

        let checkPinnedSite: @Sendable () -> Success = {
            return pinnedSites.getPinnedTopSites() >>== { pinnedSites in
                XCTAssertEqual(pinnedSites.count, 1)
                XCTAssertEqual(pinnedSites[0]?.url, site.url)
                XCTAssertEqual(pinnedSites[0]?.title, site.title)
                return succeed()
            }
        }

        let removePinnedSite: @Sendable () -> Success = {
            return pinnedSites.removeFromPinnedTopSites(site) >>== {
                return pinnedSites.getPinnedTopSites() >>== { pinnedSites in
                    XCTAssertEqual(pinnedSites.count, 0, "There should be no pinned sites")
                    return succeed()
                }
            }
        }

        addPinnedSite()
            >>> checkPinnedSite
            >>> removePinnedSite
            >>> done

        waitForExpectations(timeout: 3) { error in
            return
        }
    }
}

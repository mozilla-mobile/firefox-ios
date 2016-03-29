/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Foundation
import Storage

import XCTest

class TestHistory : ProfileTest {
    private func addSite(history: BrowserHistory, url: String, title: String, s: Bool = true) {
        let site = Site(url: url, title: title)
        let visit = SiteVisit(site: site, date: NSDate.nowMicroseconds())
        XCTAssertEqual(s, history.addLocalVisit(visit).value.isSuccess, "Site added: \(url).")
    }

    private func innerCheckSites(history: BrowserHistory, callback: (cursor: Cursor<Site>) -> Void) {
        // Retrieve the entry
        history.getSitesByLastVisit(100).upon {
            XCTAssertTrue($0.isSuccess)
            callback(cursor: $0.successValue!)
        }
    }


    private func checkSites(history: BrowserHistory, urls: [String: String], s: Bool = true) {
        // Retrieve the entry.
        if let cursor = history.getSitesByLastVisit(100).value.successValue {
            XCTAssertEqual(cursor.status, CursorStatus.Success, "Returned success \(cursor.statusMessage).")
            XCTAssertEqual(cursor.count, urls.count, "Cursor has \(urls.count) entries.")

            for index in 0..<cursor.count {
                let s = cursor[index]!
                XCTAssertNotNil(s, "Cursor has a site for entry.")
                let title = urls[s.url]
                XCTAssertNotNil(title, "Found right URL.")
                XCTAssertEqual(s.title, title!, "Found right title.")
            }
        } else {
            XCTFail("Couldn't get cursor.")
        }
    }

    private func clear(history: BrowserHistory) {
        XCTAssertTrue(history.clearHistory().value.isSuccess, "History cleared.")
    }

    private func checkVisits(history: BrowserHistory, url: String) {
        let expectation = self.expectationWithDescription("Wait for history")
        history.getSitesByLastVisit(100).upon { result in
            XCTAssertTrue(result.isSuccess)
            history.getSitesByFrecencyWithLimit(100, whereURLContains: url).upon { result in
                XCTAssertTrue(result.isSuccess)
                let cursor = result.successValue!
                XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
                // XXX - We don't allow querying much info about visits here anymore, so there isn't a lot to do
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testHistory() {
        withTestProfile { profile -> Void in
            let h = profile.history
            self.addSite(h, url: "http://url1/", title: "title")
            self.addSite(h, url: "http://url1/", title: "title")
            self.addSite(h, url: "http://url1/", title: "title 2")
            self.addSite(h, url: "https://url2/", title: "title")
            self.addSite(h, url: "https://url2/", title: "title")
            self.checkSites(h, urls: ["http://url1/": "title 2", "https://url2/": "title"])
            self.checkVisits(h, url: "http://url1/")
            self.checkVisits(h, url: "https://url2/")
            self.clear(h)
        }
    }

    func testAboutUrls() {
        withTestProfile { (profile) -> Void in
            let h = profile.history
            self.addSite(h, url: "about:home", title: "About Home", s: false)
            self.clear(h)
        }
    }

    let NumThreads = 5
    let NumCmds = 10

    func testInsertPerformance() {
        withTestProfile { profile -> Void in
            let h = profile.history
            var j = 0

            self.measureBlock({ () -> Void in
                for _ in 0...self.NumCmds {
                    self.addSite(h, url: "https://someurl\(j).com/", title: "title \(j)")
                    j++
                }
                self.clear(h)
            })
        }
    }

    func testGetPerformance() {
        withTestProfile { profile -> Void in
            let h = profile.history
            var j = 0
            var urls = [String: String]()

            self.clear(h)
            for _ in 0...self.NumCmds {
                self.addSite(h, url: "https://someurl\(j).com/", title: "title \(j)")
                urls["https://someurl\(j).com/"] = "title \(j)"
                j++
            }

            self.measureBlock({ () -> Void in
                self.checkSites(h, urls: urls)
                return
            })

            self.clear(h)
        }
    }

    // Fuzzing tests. These fire random insert/query/clear commands into the history database from threads. The don't check
    // the results. Just look for crashes.
    func testRandomThreading() {
        withTestProfile { profile -> Void in
            let queue = dispatch_queue_create("My Queue", DISPATCH_QUEUE_CONCURRENT)
            var counter = 0

            let expectation = self.expectationWithDescription("Wait for history")
            for _ in 0..<self.NumThreads {
                var history = profile.history as BrowserHistory
                self.runRandom(&history, queue: queue, cb: { () -> Void in
                    counter++
                    if counter == self.NumThreads {
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectationsWithTimeout(10, handler: nil)
        }
    }

    // Same as testRandomThreading, but uses one history connection for all threads
    func testRandomThreading2() {
        withTestProfile { profile -> Void in
            let queue = dispatch_queue_create("My Queue", DISPATCH_QUEUE_CONCURRENT)
            var history = profile.history as BrowserHistory
            var counter = 0

            let expectation = self.expectationWithDescription("Wait for history")
            for _ in 0..<self.NumThreads {
                self.runRandom(&history, queue: queue, cb: { () -> Void in
                    counter++
                    if counter == self.NumThreads {
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectationsWithTimeout(10, handler: nil)
        }
    }


    // Runs a random command on a database. Calls cb when finished.
    private func runRandom(inout history: BrowserHistory, cmdIn: Int, cb: () -> Void) {
        var cmd = cmdIn
        if cmd < 0 {
            cmd = Int(rand() % 5)
        }

        switch cmd {
        case 0...1:
            let url = "https://randomurl.com/\(rand() % 100)"
            let title = "title \(rand() % 100)"
            addSite(history, url: url, title: title)
            cb()
        case 2...3:
            innerCheckSites(history) { cursor in
                for site in cursor {
                    _ = site!
                }
            }
            cb()
        default:
            history.clearHistory().upon() { success in cb() }
        }
    }

    // Calls numCmds random methods on this database. val is a counter used by this interally (i.e. always pass zero for it).
    // Calls cb when finished.
    private func runMultiRandom(inout history: BrowserHistory, val: Int, numCmds: Int, cb: () -> Void) {
        if val == numCmds {
            cb()
            return
        } else {
            runRandom(&history, cmdIn: -1) { _ in
                self.runMultiRandom(&history, val: val+1, numCmds: numCmds, cb: cb)
            }
        }
    }

    // Helper for starting a new thread running NumCmds random methods on it. Calls cb when done.
    private func runRandom(inout history: BrowserHistory, queue: dispatch_queue_t, cb: () -> Void) {
        dispatch_async(queue) {
            // Each thread creates its own history provider
            self.runMultiRandom(&history, val: 0, numCmds: self.NumCmds) { _ in
                dispatch_async(dispatch_get_main_queue(), cb)
            }
        }
    }
}
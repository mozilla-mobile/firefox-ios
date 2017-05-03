/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Foundation
import Storage

import XCTest

class TestHistory: ProfileTest {
    fileprivate func addSite(_ history: BrowserHistory, url: String, title: String, s: Bool = true) {
        let site = Site(url: url, title: title)
        let visit = SiteVisit(site: site, date: Date.nowMicroseconds())
        XCTAssertEqual(s, history.addLocalVisit(visit).value.isSuccess, "Site added: \(url).")
    }

    fileprivate func innerCheckSites(_ history: BrowserHistory, callback: @escaping (_ cursor: Cursor<Site>) -> Void) {
        // Retrieve the entry
        history.getSitesByLastVisit(100).upon {
            XCTAssertTrue($0.isSuccess)
            callback($0.successValue!)
        }
    }

    fileprivate func checkSites(_ history: BrowserHistory, urls: [String: String], s: Bool = true) {
        // Retrieve the entry.
        if let cursor = history.getSitesByLastVisit(100).value.successValue {
            XCTAssertEqual(cursor.status, CursorStatus.success, "Returned success \(cursor.statusMessage).")
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

    fileprivate func clear(_ history: BrowserHistory) {
        XCTAssertTrue(history.clearHistory().value.isSuccess, "History cleared.")
    }

    fileprivate func checkVisits(_ history: BrowserHistory, url: String) {
        let expectation = self.expectation(description: "Wait for history")
        history.getSitesByLastVisit(100).upon { result in
            XCTAssertTrue(result.isSuccess)
            history.getSitesByFrecencyWithHistoryLimit(100, whereURLContains: url).upon { result in
                XCTAssertTrue(result.isSuccess)
                let cursor = result.successValue!
                XCTAssertEqual(cursor.status, CursorStatus.success, "returned success \(cursor.statusMessage)")
                // XXX - We don't allow querying much info about visits here anymore, so there isn't a lot to do
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 100, handler: nil)
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

            self.measure({ () -> Void in
                for _ in 0...self.NumCmds {
                    self.addSite(h, url: "https://someurl\(j).com/", title: "title \(j)")
                    j += 1
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
                j += 1
            }

            self.measure({ () -> Void in
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
            let queue = DispatchQueue(label: "My Queue", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
            var counter = 0

            let expectation = self.expectation(description: "Wait for history")
            for _ in 0..<self.NumThreads {
                var history = profile.history as BrowserHistory
                self.runRandom(&history, queue: queue, cb: { () -> Void in
                    counter += 1
                    if counter == self.NumThreads {
                        self.clear(history)
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectations(timeout: 10, handler: nil)
        }
    }

    // Same as testRandomThreading, but uses one history connection for all threads
    func testRandomThreading2() {
        withTestProfile { profile -> Void in
            let queue = DispatchQueue(label: "My Queue", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
            var history = profile.history as BrowserHistory
            var counter = 0

            let expectation = self.expectation(description: "Wait for history")
            for _ in 0..<self.NumThreads {
                self.runRandom(&history, queue: queue, cb: { () -> Void in
                    counter += 1
                    if counter == self.NumThreads {
                        self.clear(history)
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectations(timeout: 10, handler: nil)
        }
    }

    // Runs a random command on a database. Calls cb when finished.
    fileprivate func runRandom(_ history: inout BrowserHistory, cmdIn: Int, cb: @escaping () -> Void) {
        var cmd = cmdIn
        if cmd < 0 {
            cmd = Int(arc4random() % 5)
        }

        switch cmd {
        case 0...1:
            let url = "https://randomurl.com/\(arc4random() % 100)"
            let title = "title \(arc4random() % 100)"
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
    fileprivate func runMultiRandom(_ history: inout BrowserHistory, val: Int, numCmds: Int, cb: @escaping () -> Void) {
        if val == numCmds {
            cb()
            return
        } else {
            runRandom(&history, cmdIn: -1) { [history]_ in
                var history = history
                self.runMultiRandom(&history, val: val+1, numCmds: numCmds, cb: cb)
            }
        }
    }

    // Helper for starting a new thread running NumCmds random methods on it. Calls cb when done.
    fileprivate func runRandom(_ history: inout BrowserHistory, queue: DispatchQueue, cb: @escaping () -> Void) {
        queue.async { [history] in
            var history = history
            // Each thread creates its own history provider
            self.runMultiRandom(&history, val: 0, numCmds: self.NumCmds) { _ in
                DispatchQueue.main.async(execute: cb)
            }
        }
    }
}

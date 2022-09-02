// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Foundation
import Storage

import XCTest

class TestHistory: ProfileTest {
    fileprivate func addSite(_ history: BrowserHistory, url: String, title: String, bool: Bool = true) {
        let site = Site(url: url, title: title)
        let visit = SiteVisit(site: site, date: Date().toMicrosecondsSince1970())
        XCTAssertEqual(bool, history.addLocalVisit(visit).value.isSuccess, "Site added: \(url).")
    }

    fileprivate func innerCheckSites(_ history: BrowserHistory, callback: @escaping (_ cursor: Cursor<Site>) -> Void) {
        // Retrieve the entry
        history.getSitesByLastVisit(limit: 100, offset: 0).upon {
            XCTAssertTrue($0.isSuccess)
            callback($0.successValue!)
        }
    }

    fileprivate func checkSites(_ history: BrowserHistory, urls: [String: String]) {
        // Retrieve the entry.
        if let cursor = history.getSitesByLastVisit(limit: 100, offset: 0).value.successValue {
            XCTAssertEqual(cursor.status, CursorStatus.success, "Returned success \(cursor.statusMessage).")
            XCTAssertEqual(cursor.count, urls.count, "Cursor has \(urls.count) entries.")

            for index in 0..<cursor.count {
                let site = cursor[index]!
                XCTAssertNotNil(site, "Cursor has a site for entry.")
                let title = urls[site.url]
                XCTAssertNotNil(title, "Found right URL.")
                XCTAssertEqual(site.title, title!, "Found right title.")
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
        history.getSitesByLastVisit(limit: 100, offset: 0).upon { result in
            XCTAssertTrue(result.isSuccess)
            history.getFrecentHistory().getSites(matchingSearchQuery: url, limit: 100).upon { result in
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
            let history = profile.history
            self.addSite(history, url: "http://url1/", title: "title")
            self.addSite(history, url: "http://url1/", title: "title")
            self.addSite(history, url: "http://url1/", title: "title 2")
            self.addSite(history, url: "https://url2/", title: "title")
            self.addSite(history, url: "https://url2/", title: "title")
            self.checkSites(history, urls: ["http://url1/": "title 2", "https://url2/": "title"])
            self.checkVisits(history, url: "http://url1/")
            self.checkVisits(history, url: "https://url2/")
            self.clear(history)
        }
    }

    func testSearchHistory_WithResults() {
        let expectation = self.expectation(description: "Wait for search history")
        let mockProfile = MockProfile()
        mockProfile.reopen()
        let history = mockProfile.history

        let clearTest = {
            self.clear(history)
            mockProfile.shutdown()
        }

        addSite(history, url: "http://amazon.com/", title: "Amazon")
        addSite(history, url: "http://mozilla.org/", title: "Mozilla")
        addSite(history, url: "https://apple.com/", title: "Apple")
        addSite(history, url: "https://apple.developer.com/", title: "Apple Developer")

        history.getHistory(matching: "App", limit: 25, offset: 0) { results in
            XCTAssertEqual(results.count, 2)
            expectation.fulfill()
            clearTest()
        }

        self.waitForExpectations(timeout: 100, handler: nil)
    }

    func testSearchHistory_WithResultsByTitle() {
        let expectation = self.expectation(description: "Wait for search history")
        let mockProfile = MockProfile()
        mockProfile.reopen()
        let history = mockProfile.history

        let clearTest = {
            self.clear(history)
            mockProfile.shutdown()
        }

        addSite(history, url: "http://amazon.com/", title: "Amazon")
        addSite(history, url: "http://mozilla.org/", title: "Mozilla internet")
        addSite(history, url: "http://mozilla.dev.org/", title: "Internet dev")
        addSite(history, url: "https://apple.com/", title: "Apple")

        history.getHistory(matching: "int", limit: 25, offset: 0) { results in
            XCTAssertEqual(results.count, 2)
            expectation.fulfill()
            clearTest()
        }

        self.waitForExpectations(timeout: 100, handler: nil)
    }

    func testSearchHistory_WithResultsByUrl() {
        let expectation = self.expectation(description: "Wait for search history")
        let mockProfile = MockProfile()
        mockProfile.reopen()
        let history = mockProfile.history

        let clearTest = {
            self.clear(history)
            mockProfile.shutdown()
        }

        addSite(history, url: "http://amazon.com/", title: "Amazon")
        addSite(history, url: "http://mozilla.developer.org/", title: "Mozilla")
        addSite(history, url: "https://apple.developer.com/", title: "Apple")

        history.getHistory(matching: "dev", limit: 25, offset: 0) { results in
            XCTAssertEqual(results.count, 2)
            expectation.fulfill()
            clearTest()
        }

        self.waitForExpectations(timeout: 100, handler: nil)
    }

    func testSearchHistory_NoResults() {
        let expectation = self.expectation(description: "Wait for search history")
        let mockProfile = MockProfile()
        mockProfile.reopen()
        let history = mockProfile.history

        let clearTest = {
            self.clear(history)
            mockProfile.shutdown()
        }

        addSite(history, url: "http://amazon.com/", title: "Amazon")
        addSite(history, url: "http://mozilla.org/", title: "Mozilla internet")
        addSite(history, url: "https://apple.com/", title: "Apple")

        history.getHistory(matching: "red", limit: 25, offset: 0) { results in
            XCTAssertEqual(results.count, 0)
            expectation.fulfill()
            clearTest()
        }

        self.waitForExpectations(timeout: 100, handler: nil)
    }

    func testAboutUrls() {
        withTestProfile { (profile) -> Void in
            let history = profile.history
            self.addSite(history, url: "about:home", title: "About Home", bool: false)
            self.clear(history)
        }
    }

    let numThreads = 5
    let numCmds = 10

    func testInsertPerformance() {
        withTestProfile { profile -> Void in
            let history = profile.history
            var index = 0

            self.measure({ () -> Void in
                for _ in 0...self.numCmds {
                    self.addSite(history, url: "https://someurl\(index).com/", title: "title \(index)")
                    index += 1
                }
                self.clear(history)
            })
        }
    }

    func testGetPerformance() {
        withTestProfile { profile -> Void in
            let history = profile.history
            var index = 0
            var urls = [String: String]()

            self.clear(history)
            for _ in 0...self.numCmds {
                self.addSite(history, url: "https://someurl\(index).com/", title: "title \(index)")
                urls["https://someurl\(index).com/"] = "title \(index)"
                index += 1
            }

            self.measure({ () -> Void in
                self.checkSites(history, urls: urls)
                return
            })

            self.clear(history)
        }
    }

    // Fuzzing tests. These fire random insert/query/clear commands into the history database from threads. The don't check
    // the results. Just look for crashes.
    func testRandomThreading() {
        withTestProfile { profile -> Void in
            let queue = DispatchQueue(label: "My Queue",
                                      qos: DispatchQoS.default,
                                      attributes: DispatchQueue.Attributes.concurrent,
                                      autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
                                      target: nil)
            var counter = 0

            let expectation = self.expectation(description: "Wait for history")
            for _ in 0..<self.numThreads {
                var history = profile.history as BrowserHistory
                self.runRandom(&history, queue: queue, completion: { () -> Void in
                    counter += 1
                    if counter == self.numThreads {
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
            let queue = DispatchQueue(label: "My Queue",
                                      qos: DispatchQoS.default,
                                      attributes: DispatchQueue.Attributes.concurrent,
                                      autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
                                      target: nil)
            var history = profile.history as BrowserHistory
            var counter = 0

            let expectation = self.expectation(description: "Wait for history")
            for _ in 0..<self.numThreads {
                self.runRandom(&history, queue: queue, completion: { () -> Void in
                    counter += 1
                    if counter == self.numThreads {
                        self.clear(history)
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectations(timeout: 10, handler: nil)
        }
    }

    // Runs a random command on a database. Calls cb when finished.
    fileprivate func runRandom(
        _ history: inout BrowserHistory,
        cmdIn: Int,
        completion: @escaping () -> Void
    ) {
        var cmd = cmdIn
        if cmd < 0 {
            cmd = Int(arc4random() % 5)
        }

        switch cmd {
        case 0...1:
            let url = "https://randomurl.com/\(arc4random() % 100)"
            let title = "title \(arc4random() % 100)"
            addSite(history, url: url, title: title)
            completion()
        case 2...3:
            innerCheckSites(history) { cursor in
                for site in cursor {
                    _ = site!
                }
            }
            completion()
        default:
            history.clearHistory().upon { success in completion() }
        }
    }

    // Calls numCmds random methods on this database. val is a counter used by this interally (i.e. always pass zero for it).
    // Calls cb when finished.
    fileprivate func runMultiRandom(
        _ history: inout BrowserHistory,
        val: Int, numCmds: Int,
        completion: @escaping () -> Void
    ) {
        if val == numCmds {
            completion()
            return
        } else {
            runRandom(&history, cmdIn: -1) { [history] in
                var history = history
                self.runMultiRandom(&history, val: val+1, numCmds: numCmds, completion: completion)
            }
        }
    }

    // Helper for starting a new thread running NumCmds random methods on it. Calls cb when done.
    fileprivate func runRandom(
        _ history: inout BrowserHistory,
        queue: DispatchQueue,
        completion: @escaping () -> Void
    ) {
        queue.async { [history] in
            var history = history
            // Each thread creates its own history provider
            self.runMultiRandom(&history, val: 0, numCmds: self.numCmds) {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }
}

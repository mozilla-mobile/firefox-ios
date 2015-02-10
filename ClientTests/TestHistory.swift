import Foundation
import XCTest
import Storage

class TestHistory : AccountTest {

    private func innerAddSite(history: History, url: String, title: String, callback: (success: Bool) -> Void) {
        // Add an entry
        let site = Site(url: url, title: title)
        let visit = Visit(site: site, date: NSDate())
        history.addVisit(visit) { success in
            callback(success: success)
        }
    }

    private func addSite(history: History, url: String, title: String, s: Bool = true) {
        let expectation = self.expectationWithDescription("Wait for history")
        innerAddSite(history, url: url, title: title) { success in
            XCTAssertEqual(success, s, "Site added \(url)")
            expectation.fulfill()
        }
    }

    private func innerCheckSites(history: History, callback: (cursor: Cursor) -> Void) {
        // Retrieve the entry
        history.get(nil, complete: { cursor in
            callback(cursor: cursor)
        })
    }


    private func checkSites(history: History, urls: [String: String], s: Bool = true) {
        let expectation = self.expectationWithDescription("Wait for history")

        // Retrieve the entry
        innerCheckSites(history) { cursor in
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, urls.count, "cursor has \(urls.count) entries")

            for index in 0..<cursor.count {
                let s = cursor[index] as Site
                XCTAssertNotNil(s, "cursor has a site for entry")
                let title = urls[s.url]
                XCTAssertNotNil(title, "Found right url")
                XCTAssertEqual(s.title, title!, "Found right title")
            }
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    private func innerClear(history: History, callback: (s: Bool) -> Void) {
        history.clear({ success in
            callback(s: success)
        })
    }

    private func clear(history: History, s: Bool = true) {
        let expectation = self.expectationWithDescription("Wait for history")

        innerClear(history) { success in
            XCTAssertEqual(s, success, "Sites cleared")
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    private func checkVisits(history: History, url: String) {
        let expectation = self.expectationWithDescription("Wait for history")
        history.get(nil) { cursor in
            let options = QueryOptions()
            options.filter = url
            history.get(options) { cursor in
                XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
                // XXX - We don't allow querying much info about visits here anymore, so there isn't a lot to do
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testHistory() {
        withTestAccount { account -> Void in
            let h = account.history
            self.addSite(h, url: "url1", title: "title")
            self.addSite(h, url: "url1", title: "title")
            self.addSite(h, url: "url1", title: "title 2")
            self.addSite(h, url: "url2", title: "title")
            self.addSite(h, url: "url2", title: "title")
            self.checkSites(h, urls: ["url1": "title 2", "url2": "title"])
            self.checkVisits(h, url: "url1")
            self.checkVisits(h, url: "url2")
            self.clear(h)
            account.files.remove("browser.db", basePath: nil)
        }
    }

    let NumThreads = 5
    let NumCmds = 10

    func testInsertPerformance() {
        withTestAccount { account -> Void in
            let h = account.history
            var j = 0

            self.measureBlock({ () -> Void in
                for i in 0...self.NumCmds {
                    self.addSite(h, url: "url \(j)", title: "title \(j)")
                    j++
                }
                self.clear(h)
            })
            account.files.remove("browser.db", basePath: nil)
        }
    }

    func testGetPerformance() {
        withTestAccount { account -> Void in
            let h = account.history
            var j = 0
            var urls = [String: String]()

            self.clear(h)
            for i in 0...self.NumCmds {
                self.addSite(h, url: "url \(j)", title: "title \(j)")
                urls["url \(j)"] = "title \(j)"
                j++
            }

            self.measureBlock({ () -> Void in
                self.checkSites(h, urls: urls)
                return
            })

            self.clear(h)
            account.files.remove("browser.db", basePath: nil)
        }
    }

    // Fuzzing tests. These fire random insert/query/clear commands into the history database from threads. The don't check
    // the results. Just look for crashes.
    func testRandomThreading() {
        withTestAccount { account -> Void in
            var queue = dispatch_queue_create("My Queue", DISPATCH_QUEUE_CONCURRENT)
            var done = [Bool]()
            var counter = 0

            let expectation = self.expectationWithDescription("Wait for history")
            for i in 0..<self.NumThreads {
                var history = account.history
                self.runRandom(&history, queue: queue, cb: { () -> Void in
                    counter++
                    if counter == self.NumThreads {
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectationsWithTimeout(10, handler: nil)

            account.files.remove("browser.db", basePath: nil)
        }
    }

    // Same as testRandomThreading, but uses one history connection for all threads
    func testRandomThreading2() {
        withTestAccount { account -> Void in
            var queue = dispatch_queue_create("My Queue", DISPATCH_QUEUE_CONCURRENT)
            var history = account.history
            var counter = 0

            let expectation = self.expectationWithDescription("Wait for history")
            for i in 0..<self.NumThreads {
                self.runRandom(&history, queue: queue, cb: { () -> Void in
                    counter++
                    if counter == self.NumThreads {
                        expectation.fulfill()
                    }
                })
            }
            self.waitForExpectationsWithTimeout(10, handler: nil)

            account.files.remove("browser.db", basePath: nil)
        }
    }


    // Runs a random command on a database. Calls cb when finished
    private func runRandom(inout history: History, cmdIn: Int, cb: () -> Void) {
        var cmd = cmdIn
        if cmd < 0 {
            cmd = Int(rand() % 5)
        }

        switch cmd {
        case 0...1:
            let url = "url \(rand() % 100)"
            let title = "title \(rand() % 100)"
            innerAddSite(history, url: url, title: title) { success in cb() }
        case 2...3:
            innerCheckSites(history) { cursor in
                for site in cursor {
                    let s = site as Site
                }
            }
            cb()
        default:
            innerClear(history) { success in cb() }
        }
    }

    // Calls numCmds random methods on this database. val is a counter used by this interally (i.e. always pass zero for it)
    // Calls cb when finished
    private func runMultiRandom(inout history: History, val: Int, numCmds: Int, cb: () -> Void) {
        if val == numCmds {
            cb()
            return
        } else {
            runRandom(&history, cmdIn: -1) { _ in
                self.runMultiRandom(&history, val: val+1, numCmds: numCmds, cb: cb)
            }
        }
    }

    // Helper for starting a new thread running NumCmds random methods on it. Calls cb when done
    private func runRandom(inout history: History, queue: dispatch_queue_t, cb: () -> Void) {
        dispatch_async(queue) {
            // Each thread creates its own history provider
            self.runMultiRandom(&history, val: 0, numCmds: self.NumCmds) { _ in
                dispatch_async(dispatch_get_main_queue(), cb)
            }
        }
    }
}
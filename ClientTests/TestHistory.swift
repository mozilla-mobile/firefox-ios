import Foundation
import XCTest

class TestHistory : AccountTest {

    private func addSite(history: History, url: String, title: String, s: Bool = true) {
        let expectation = self.expectationWithDescription("Wait for history")

        // Add an entry
        history.addVisit(Site(url: url, title: title), options: nil) { success in
            XCTAssertEqual(success, s, "Site added")
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    private func getSites(history: History, urls: [String], titles: [String], s: Bool = true) {
        let expectation = self.expectationWithDescription("Wait for history")

        // Retrieve the entry
        history.get(nil, options: nil, complete: { cursor in
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, urls.count, "cursor has one entry")

            for (index, url) in enumerate(urls) {
                let s = cursor[index] as? Site
                XCTAssertNotNil(s, "cursor has a site for entry")
                XCTAssertEqual(s!.url, url, "Found right url")
                XCTAssertEqual(s!.title, titles[index], "Found right title")
            }

            expectation.fulfill()
        })

        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    private func clear(history: History) {
        let expectation = self.expectationWithDescription("Wait for history")

        // Clear the database
        history.clear(nil, options: nil, complete: { success in
            XCTAssertTrue(success, "Sites cleared")
            // TODO: We don't have good cleanup for profile's here yet, so make sure we cleanup when we're done
            expectation.fulfill()
        })

        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testSqliteHistory() {
        withTestAccount { account -> Void in
            let h = SqliteHistory(profile: account)
            self.addSite(h, url: "url", title: "title")
            self.addSite(h, url: "url", title: "title", s: false) // Adding the same url twice should fail
            self.getSites(h, urls: ["url"], titles: ["title"])
            self.clear(h)
            account.files.remove("browser.db")
        }
    }
}
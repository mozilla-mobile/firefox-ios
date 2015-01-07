import Foundation
import XCTest

class TestHistory : AccountTest {

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testSqliteHistory() {
        withTestAccount { account -> Void in
            let h = SqliteHistory(profile: account)
            let expectation = self.expectationWithDescription("Wait for history")

            // Add an entry
            h.addVisit(Site(url: "url", title: "title"), options: nil) { success in
                XCTAssertTrue(success, "Site added")

                // Retrieve the entry
                h.get(nil, options: nil, complete: { cursor in
                    XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
                    XCTAssertEqual(cursor.count, 1, "cursor has one entry")
                    let s = cursor[0] as? Site
                    XCTAssertNotNil(s, "cursor has a site for entry")
                    XCTAssertEqual(s!.url, "url", "Found right url")
                    XCTAssertEqual(s!.title, "title", "Found right title")

                    // Clear the database
                    h.clear(nil, options: nil, complete: { success in
                        XCTAssertTrue(success, "Sites cleared")
                        // TODO: We don't have good cleanup for profile's here yet, so make sure we cleanup when we're done
                        account.files.remove("browser.db")
                        expectation.fulfill()
                    })
                })
            }

            self.waitForExpectationsWithTimeout(100, handler: nil)
        }
    }

    // Tests adding the same site twice should fail
    func testAddTwice() {
        withTestAccount { account -> Void in
            let h = SqliteHistory(profile: account)
            let expectation = self.expectationWithDescription("Wait for history")

            h.addVisit(Site(url: "url", title: "title"), options: nil) { success in
                XCTAssertTrue(success, "Site added")
                h.addVisit(Site(url: "url", title: "title"), options: nil) { success in
                    XCTAssertFalse(success, "Site not added twice")

                    h.get(nil, options: nil, complete: { cursor in
                        XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
                        XCTAssertEqual(cursor.count, 1, "cursor has one entry")

                        h.clear(nil, options: nil, complete: { success in
                            XCTAssertTrue(success, "Sites cleared")
                            // TODO: We don't have good cleanup for profile's here yet, so make sure we cleanup when we're done
                            account.files.remove("browser.db")
                            expectation.fulfill()
                        })
                    })
                }
            }

            self.waitForExpectationsWithTimeout(100, handler: nil)
        }
    }
}
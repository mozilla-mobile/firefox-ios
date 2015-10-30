import Foundation
import XCTest
import Storage

class TestFavicons : ProfileTest {

    private func innerAddIcon(favicons: Favicons, url: String, callback: (success: Bool) -> Void) {
        // Add an entry
    }

    private func addSite(favicons: Favicons, url: String, s: Bool = true) {
        let expectation = self.expectationWithDescription("Wait for history")
        let site = Site(url: url, title: "")
        let icon = Favicon(url: url + "/icon.png", type: IconType.Icon)
        favicons.addFavicon(icon, forSite: site).upon {
            XCTAssertEqual($0.isSuccess, s, "Icon added \(url)")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    // TODO: uncomment.
    /*
    private func checkSites(favicons: Favicons, icons: [String], s: Bool = true) {
        let expectation = self.expectationWithDescription("Wait for history")

        // Retrieve the entry
        let opts: QueryOptions? = nil
        favicons.get(opts, complete: { cursor in
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, icons.count, "cursor has \(icons.count) entries")

            for index in 0..<cursor.count {
                let (site, favicon) = cursor[index]!
                XCTAssertNotNil(s, "cursor has a favicon for entry")
                let index = find(icons, favicon.url)
                XCTAssertNotNil(index, "Found expected entry \(favicon.url)")
            }
            expectation.fulfill()
        })

        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    private func clear(favicons: Favicons, s: Bool = true) {
        let expectation = self.expectationWithDescription("Wait for history")

        let opts: QueryOptions? = nil
        favicons.clear(opts) { (success) -> Void in
            XCTAssertEqual(s, success, "Sites cleared")
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(100, handler: nil)
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testFavicons() {
        withTestProfile { profile -> Void in
            let h = profile.favicons
            self.addSite(h, url: "url1")
            self.addSite(h, url: "url1")
            self.addSite(h, url: "url1")
            self.addSite(h, url: "url2")
            self.addSite(h, url: "url2")
            self.checkSites(h, icons: ["url1/icon.png", "url2/icon.png"], s: true)

            // TODO: Use the local file server for URLs here, so that we can test download/save/delete of local storage
            self.clear(h)
            profile.files.remove("mock.db")
        }
    }
    */
}
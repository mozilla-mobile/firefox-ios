// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import SiteImageView

class ImageURLFetcherTests: XCTestCase {

    var subject: DefaultImageURLFetcher!

    override func setUp() {
        subject = DefaultImageURLFetcher()
    }

    func testGetFaviconWithFallbackIcon() {
        let expectation = self.expectation(description: "Wait for Favicons to be fetched")
        let url = URL(string: "http://www.google.com")!
        subject.fetchFaviconURL(siteURL: url) { result in
            print("Here")
        }
        self.waitForExpectations(timeout: 3000, handler: nil)
    }
}
//
//extension ImageURLFetcherTests {
//
//    let mockHTML = """
//                    <html>
//                        <head>
//                            <link rel="icon" href="image.png"></link>
//                            <title>Page {page}</title>
//                        </head>
//                    </html>
//                    """
//
//}

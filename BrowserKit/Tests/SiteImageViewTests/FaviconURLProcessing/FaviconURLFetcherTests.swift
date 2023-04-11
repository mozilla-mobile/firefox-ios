// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

class FaviconURLFetcherTests: XCTestCase {
    var subject: DefaultFaviconURLFetcher!
    var networkMock: HTMLDataRequestMock!

    override func setUp() {
        super.setUp()
        networkMock = HTMLDataRequestMock()
        subject = DefaultFaviconURLFetcher(network: networkMock)
    }

    override func tearDown() {
        super.tearDown()
        networkMock = nil
        subject = nil
    }

    func testGetFaviconWithExistingIcon() async {
        let url = URL(string: "http://firefox.com")!
        networkMock.data = generateHTMLData(string: ImageURLTestHTML.mockHTMLWithIcon)
        do {
            let result = try await subject.fetchFaviconURL(siteURL: url)
            XCTAssertEqual(result.absoluteString, "http://firefox.com/image.png")
        } catch {
            XCTFail("Failed to fetch favicon with existing icon")
        }
    }

    func testGetFaviconWithNoIconFallback() async {
        let url = URL(string: "http://firefox.com")!
        networkMock.data = generateHTMLData(string: ImageURLTestHTML.mockHTMLWithNoIcon)
        do {
            let result = try await subject.fetchFaviconURL(siteURL: url)
            XCTAssertEqual(result.absoluteString, "http://firefox.com/favicon.ico")
        } catch {
            XCTFail("Failed to fetch favicon with no icon using fallback ico")
        }
    }

    // MARK: - Private helpers

    private func generateHTMLData(string: String) -> Data? {
        return string.data(using: .utf8)
    }
}

// MARK: - Mock HTML Data

private enum ImageURLTestHTML {
    static let mockHTMLWithIcon = """
        <html>
            <head>
                <link rel="icon" href="http://firefox.com/image.png"></link>
                <title>Firefox</title>
            </head>
        </html>
        """

    static let mockHTMLWithNoIcon = """
        <html>
            <head>
                <title>Firefox</title>
            </head>
        </html>
        """
}

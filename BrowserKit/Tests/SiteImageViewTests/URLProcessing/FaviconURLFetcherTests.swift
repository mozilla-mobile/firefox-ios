// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import SiteImageView

class FaviconURLFetcherTests: XCTestCase {

    var subject: DefaultFaviconURLFetcher!
    var networkMock: NetworkRequestMock!

    override func setUp() {
        super.setUp()
        networkMock = NetworkRequestMock()
        subject = DefaultFaviconURLFetcher(network: networkMock)
    }

    override func tearDown() {
        super.tearDown()
        networkMock = nil
        subject = nil
    }

    func testGetFaviconWithExistingIcon() {
        let url = URL(string: "http://firefox.com")!

        subject.fetchFaviconURL(siteURL: url) { result in
            switch result {
            case let .success(url):
                XCTAssertEqual(url.absoluteString, "http://firefox.com/image.png")
            default:
                XCTFail("Failed to retrieve favicon URL")
            }
        }

        guard let data = generateHTMLData(string: ImageURLTestHTML.mockHTMLWithIcon) else {
            XCTFail("Invalid test HTML")
            return
        }
        networkMock.callFetchDataForURLCompletion(with: .success(data))
    }

    func testGetFaviconWithNoIconFallback() {
        let url = URL(string: "http://firefox.com")!

        subject.fetchFaviconURL(siteURL: url) { result in
            switch result {
            case let .success(url):
                XCTAssertEqual(url.absoluteString, "http://firefox.com/favicon.ico")
            default:
                XCTFail("Failed to retrieve favicon URL")
            }
        }

        guard let data = generateHTMLData(string: ImageURLTestHTML.mockHTMLWithNoIcon) else {
            XCTFail("Invalid test HTML")
            return
        }
        networkMock.callFetchDataForURLCompletion(with: .success(data))
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
                <link rel="icon" href="image.png"></link>
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

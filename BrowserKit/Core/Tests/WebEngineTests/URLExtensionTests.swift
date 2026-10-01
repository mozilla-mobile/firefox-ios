// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class URLExtensionTests: XCTestCase {
    private let webserverPort = 6571

    // MARK: encodeReaderModeURL tests

    func testEncodeReaderModeURLGivenReaderAndURLThenEncodeReaderURL() {
        let readerURL = "http://localhost:\(webserverPort)/reader-mode/page"
        let stringURL = "https://en.m.wikipedia.org/wiki/Main_Page"
        let expectedReaderModeURL = URL(string: "http://localhost:\(webserverPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage")

        XCTAssertEqual(URL(string: stringURL)!.encodeReaderModeURL(readerURL), expectedReaderModeURL)
    }
}

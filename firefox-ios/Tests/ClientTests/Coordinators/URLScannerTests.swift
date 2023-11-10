// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class URLScannerTests: XCTestCase {
    func testValidURL() {
        let urlString = "https://www.example.com/path/to/resource?key=value"
        let url = URL(string: urlString)!
        let scanner = URLScanner(url: url)
        XCTAssertNotNil(scanner)
        XCTAssertEqual(scanner?.scheme, "https")
        XCTAssertEqual(scanner?.host, "www.example.com")
        XCTAssertEqual(scanner?.components, ["/", "path", "to", "resource"])
        XCTAssertEqual(scanner?.queries.count, 1)
        XCTAssertEqual(scanner?.value(query: "key"), "value")
    }

    func testInvalidScheme() {
        let urlString = "ftp://www.example.com"
        let url = URL(string: urlString)!
        let scanner = URLScanner(url: url)
        XCTAssertNil(scanner)
    }

    func testMissingHost() {
        let urlString = "https:///path/to/resource?key=value"
        let url = URL(string: urlString)!
        let scanner = URLScanner(url: url)!
        XCTAssertTrue(scanner.host.isEmpty)
    }

    func testEmptyPath() {
        let urlString = "https://www.example.com?key=value"
        let url = URL(string: urlString)!
        let scanner = URLScanner(url: url)
        XCTAssertNotNil(scanner)
        XCTAssertEqual(scanner?.components, [])
    }

    func testInvalidQuery() {
        let urlString = "https://www.example.com?key1=value1&key2="
        let url = URL(string: urlString)!
        let scanner = URLScanner(url: url)
        XCTAssertNotNil(scanner)
        XCTAssertEqual(scanner?.queries.count, 2)
        XCTAssertEqual(scanner?.value(query: "key1"), "value1")
        XCTAssertEqual(scanner?.value(query: "key2"), "")
        XCTAssertNil(scanner?.value(query: "nonexistent"))
    }

    func testOurScheme() {
        let urlString = "firefox://abcdefg/path/to/resource"
        let url = URL(string: urlString)!
        let scanner = URLScanner(url: url)
        XCTAssertNotNil(scanner)
        XCTAssertTrue(scanner!.isOurScheme)
    }

    func testHTTPScheme() {
        let urlString = "http://www.example.com"
        let url = URL(string: urlString)!
        let scanner = URLScanner(url: url)
        XCTAssertNotNil(scanner)
        XCTAssertTrue(scanner!.isHTTPScheme)
    }

    func testSanitizedScheme() {
        let urlString = "HtTpS://www.example.com"
        let url = URL(string: urlString)!
        let sanitizedURL = URLScanner.sanitized(url: url)
        XCTAssertEqual(sanitizedURL.scheme, "https")
        XCTAssertEqual(sanitizedURL.host, "www.example.com")
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

@testable import Client

class URLMailTests: XCTestCase {
    func testMailToMetadata_noMailto() {
        let url = URL(string: "https://test.com")
        XCTAssertNil(url!.mailToMetadata(), "Metadata should be nil")
    }

    func testMailToMetadata_emailOnly() {
        let url = URL(string: "mailto:someone@example.com")
        let metadata = url!.mailToMetadata()
        XCTAssertNotNil(metadata, "Metadata should not be nil")
        XCTAssertEqual(metadata?.to, "someone@example.com", "Should have a to value")
        XCTAssertEqual(metadata?.headers.count, 0, "Should have no headers")
    }

    func testMailToMetadata_multipleEmails() {
        let url = URL(string: "mailto:someone@example.com,someoneelse@example.com")
        let metadata = url!.mailToMetadata()
        XCTAssertNotNil(metadata, "Metadata should not be nil")
        XCTAssertEqual(metadata?.to, "someone@example.com,someoneelse@example.com", "Should have a to value")
        XCTAssertEqual(metadata?.headers.count, 0, "Should have no headers")
    }

    func testMailToMetadata_headerFields() {
        let url = URL(string: "mailto:someone@example.com?subject=This%20is%20the%20subject&cc=someone_else@example.com&body=This%20is%20the%20body")
        let metadata = url!.mailToMetadata()
        XCTAssertNotNil(metadata, "Metadata should not be nil")
        XCTAssertEqual(metadata?.to, "someone@example.com", "Should have a to value")
        XCTAssertEqual(metadata?.headers.count, 3, "Should have 3 headers")
        XCTAssertEqual(metadata?.headers["subject"], "This is the subject")
        XCTAssertEqual(metadata?.headers["cc"], "someone_else@example.com")
        XCTAssertEqual(metadata?.headers["body"], "This is the body")
    }

    func testMailToMetadata_noToAddress() {
        let url = URL(string: "mailto:?to=&subject=mailto%20with%20examples&body=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FMailto")
        let metadata = url!.mailToMetadata()
        XCTAssertNotNil(metadata, "Metadata should not be nil")
        XCTAssertEqual(metadata?.to, "", "Should have empty to value")
        XCTAssertEqual(metadata?.headers.count, 3, "Should have 3 headers")
        XCTAssertEqual(metadata?.headers["subject"], "mailto with examples")
        XCTAssertEqual(metadata?.headers["body"], "https://en.wikipedia.org/wiki/Mailto")
    }

    func testMailToMetadata_blubb() {
        let url = URL(string: "mailto:someone@example.com?subject=This%20is%20the%20subject&body")
        let metadata = url!.mailToMetadata()
        XCTAssertNotNil(metadata, "Metadata should not be nil")
        XCTAssertEqual(metadata?.to, "someone@example.com", "Should have a to value")
        XCTAssertEqual(metadata?.headers.count, 1, "Should have 1 headers")
        XCTAssertEqual(metadata?.headers["subject"], "This is the subject")
    }
}

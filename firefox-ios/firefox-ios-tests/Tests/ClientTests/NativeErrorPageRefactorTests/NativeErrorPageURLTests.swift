// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

final class NativeErrorPageURLTests: XCTestCase {
    private let originalURL = URL(string: "https://example.com")!

    func testMake_readsBackSameValues() throws {
        let subject = try XCTUnwrap(NativeErrorPageURL.make(type: .noInternet,
                                                            originalURL: originalURL,
                                                            errorCode: NSURLErrorNotConnectedToInternet))

        XCTAssertEqual(subject.type, .noInternet)
        XCTAssertEqual(subject.originalURL, originalURL)
        XCTAssertEqual(subject.errorCode, NSURLErrorNotConnectedToInternet)
        XCTAssertNil(subject.certificateData)
    }

    func testMake_withCertificateData_readsBackCertificateData() throws {
        let certificateData = Data("certificate".utf8)
        let subject = try XCTUnwrap(NativeErrorPageURL.make(type: .badCert,
                                                            originalURL: originalURL,
                                                            errorCode: NSURLErrorServerCertificateUntrusted,
                                                            certificateData: certificateData))

        XCTAssertEqual(subject.certificateData, certificateData)
    }

    func testMake_createsErrorPageInternalURL() throws {
        let subject = try XCTUnwrap(NativeErrorPageURL.make(type: .generic, originalURL: originalURL, errorCode: -1))

        XCTAssertTrue(subject.internalURL.isErrorPage)
        XCTAssertEqual(subject.internalURL.originalURLFromErrorPage, originalURL)
    }

    func testInit_notErrorPage_returnsNil() throws {
        let internalURL = try XCTUnwrap(InternalURL(URL(string: "internal://local/about/home")))
        XCTAssertNil(NativeErrorPageURL(internalURL: internalURL))
    }

    func testInit_missingCode_returnsNil() throws {
        let internalURL = try XCTUnwrap(InternalURL(URL(string: "internal://local/errorpage?url=https://example.com")))
        XCTAssertNil(NativeErrorPageURL(internalURL: internalURL))
    }

    func testInit_missingType_defaultsToGeneric() throws {
        let url = URL(string: "internal://local/errorpage?url=https://example.com&code=-1009")
        let internalURL = try XCTUnwrap(InternalURL(url))
        let subject = try XCTUnwrap(NativeErrorPageURL(internalURL: internalURL))

        XCTAssertEqual(subject.type, .generic)
    }

    func testInit_unknownType_defaultsToGeneric() throws {
        let url = URL(string: "internal://local/errorpage?url=https://example.com&code=-1009&type=unknown")
        let internalURL = try XCTUnwrap(InternalURL(url))
        let subject = try XCTUnwrap(NativeErrorPageURL(internalURL: internalURL))

        XCTAssertEqual(subject.type, .generic)
    }

    func testEquality_ignoresAuthorization() throws {
        let subject = try XCTUnwrap(NativeErrorPageURL.make(type: .generic, originalURL: originalURL, errorCode: -1))
        let authorizedURL = try XCTUnwrap(InternalURL.authorize(url: subject.url))
        let authorizedInternalURL = try XCTUnwrap(InternalURL(authorizedURL))
        let authorized = try XCTUnwrap(NativeErrorPageURL(internalURL: authorizedInternalURL))

        XCTAssertEqual(subject, authorized)
    }
}

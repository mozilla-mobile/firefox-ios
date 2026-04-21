// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

final class ErrorPageHandlerTests: XCTestCase {
    @MainActor
    func testResponseForErrorWebPage_withCertificateErrorWithoutCertErrorQuery_usesFallbackAndDoesNotCrash() {
        let subject = ErrorPageHandler()
        let errorURL = URL(
            string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)"
            + "?url=https%3A%2F%2Fexpired.badssl.com%2F"
            + "&code=\(NSURLErrorServerCertificateUntrusted)"
            + "&description=SSL%20error"
            + "&domain=\(NSURLErrorDomain)"
        )!

        let result = subject.responseForErrorWebPage(request: URLRequest(url: errorURL))

        XCTAssertNotNil(result)
        let html = String(data: result?.1 ?? Data(), encoding: .utf8)
        XCTAssertEqual(html?.contains("SEC_ERROR_UNKNOWN_ISSUER"), true)
    }

    @MainActor
    func testResponseForErrorWebPage_withCertErrorQuery_usesProvidedValue() {
        let subject = ErrorPageHandler()
        let errorURL = URL(
            string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)"
            + "?url=https%3A%2F%2Fexpired.badssl.com%2F"
            + "&code=\(NSURLErrorServerCertificateUntrusted)"
            + "&description=SSL%20error"
            + "&domain=\(NSURLErrorDomain)"
            + "&certerror=SEC_ERROR_EXPIRED_CERTIFICATE"
        )!

        let result = subject.responseForErrorWebPage(request: URLRequest(url: errorURL))

        XCTAssertNotNil(result)
        let html = String(data: result?.1 ?? Data(), encoding: .utf8)
        XCTAssertEqual(html?.contains("SEC_ERROR_EXPIRED_CERTIFICATE"), true)
    }

    @MainActor
    func testResponseForErrorWebPage_withBadDateErrorWithoutCertErrorQuery_usesExpiredFallback() {
        let subject = ErrorPageHandler()
        let errorURL = URL(
            string: "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)"
            + "?url=https%3A%2F%2Fexpired.badssl.com%2F"
            + "&code=\(NSURLErrorServerCertificateHasBadDate)"
            + "&description=SSL%20error"
            + "&domain=\(NSURLErrorDomain)"
        )!

        let result = subject.responseForErrorWebPage(request: URLRequest(url: errorURL))

        XCTAssertNotNil(result)
        let html = String(data: result?.1 ?? Data(), encoding: .utf8)
        XCTAssertEqual(html?.contains("SEC_ERROR_EXPIRED_CERTIFICATE"), true)
    }
}

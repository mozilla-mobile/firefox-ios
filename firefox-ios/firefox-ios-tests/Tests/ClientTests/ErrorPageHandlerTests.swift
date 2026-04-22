// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import WebKit
import Shared

@testable import Client

final class ErrorPageHandlerTests: XCTestCase {
    @MainActor
    func testResponseForErrorWebPage_withCertificateErrorWithoutCertErrorQuery_usesFallbackAndDoesNotCrash() {
        assertErrorPageContainsCertError(
            networkErrorCode: NSURLErrorServerCertificateUntrusted,
            certErrorQuery: nil,
            expectedCertError: "SEC_ERROR_UNKNOWN_ISSUER"
        )
    }

    @MainActor
    func testResponseForErrorWebPage_withCertErrorQuery_usesProvidedValue() {
        assertErrorPageContainsCertError(
            networkErrorCode: NSURLErrorServerCertificateUntrusted,
            certErrorQuery: "SEC_ERROR_EXPIRED_CERTIFICATE",
            expectedCertError: "SEC_ERROR_EXPIRED_CERTIFICATE"
        )
    }

    @MainActor
    func testResponseForErrorWebPage_withBadDateErrorWithoutCertErrorQuery_usesExpiredFallback() {
        assertErrorPageContainsCertError(
            networkErrorCode: NSURLErrorServerCertificateHasBadDate,
            certErrorQuery: nil,
            expectedCertError: "SEC_ERROR_EXPIRED_CERTIFICATE"
        )
    }

    @MainActor
    func testLoadPage_withCertificateErrorWithoutUnderlyingError_stillAddsCertErrorQuery() {
        let subject = ErrorPageHelper(certStore: nil)
        let webView = MockTabWebView(
            frame: .zero,
            configuration: WKWebViewConfiguration(),
            windowUUID: .XCTestDefaultUUID
        )
        let failingURL = URL(string: "https://expired.badssl.com/")!
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted)

        subject.loadPage(error, forUrl: failingURL, inWebView: webView)

        let loadedURL = try? XCTUnwrap(webView.loadedRequest?.url)
        let components = loadedURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let certError = components?.queryItems?.first(where: { $0.name == "certerror" })?.value
        XCTAssertEqual(certError, "SEC_ERROR_UNKNOWN_ISSUER")
    }
}

private extension ErrorPageHandlerTests {
    @MainActor
    func assertErrorPageContainsCertError(
        networkErrorCode: Int,
        certErrorQuery: String?,
        expectedCertError: String
    ) {
        let subject = ErrorPageHandler()
        let errorURL = makeErrorPageURL(networkErrorCode: networkErrorCode, certErrorQuery: certErrorQuery)

        let result = subject.responseForErrorWebPage(request: URLRequest(url: errorURL))

        XCTAssertNotNil(result)
        let html = String(data: result?.1 ?? Data(), encoding: .utf8)
        XCTAssertEqual(html?.contains(expectedCertError), true)
    }

    func makeErrorPageURL(networkErrorCode: Int, certErrorQuery: String?) -> URL {
        var urlString = "\(InternalURL.baseUrl)/\(InternalURL.Path.errorpage.rawValue)"
            + "?url=https%3A%2F%2Fexpired.badssl.com%2F"
            + "&code=\(networkErrorCode)"
            + "&description=SSL%20error"
            + "&domain=\(NSURLErrorDomain)"
        if let certErrorQuery {
            urlString += "&certerror=\(certErrorQuery)"
        }
        return URL(string: urlString)!
    }
}

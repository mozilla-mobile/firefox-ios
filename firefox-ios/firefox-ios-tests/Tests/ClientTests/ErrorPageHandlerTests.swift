// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Shared

@testable import Client

final class ErrorPageHandlerTests: XCTestCase {
    private struct MockCellularDataStateProvider: CellularDataStateProvider {
        let isRestricted: Bool
    }

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    func testSystemCellularDataStateProvider_sharedInstance_isStableAcrossReloads() {
        let firstLoadProvider = SystemCellularDataStateProvider.shared
        let reloadedPageProvider = SystemCellularDataStateProvider.shared

        XCTAssertTrue(firstLoadProvider === reloadedPageProvider)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try super.tearDownWithError()
    }

    @MainActor
    func testResponseForErrorWebPage_withCertificateErrorWithoutCertErrorQuery_usesFallbackAndDoesNotCrash() {
        assertErrorPageContainsCertError(
            networkErrorCode: NSURLErrorServerCertificateUntrusted,
            certErrorQuery: nil,
            expectedCertError: certErrorUnknownIssuer
        )
    }

    @MainActor
    func testResponseForErrorWebPage_withCertErrorQuery_usesProvidedValue() {
        assertErrorPageContainsCertError(
            networkErrorCode: NSURLErrorServerCertificateUntrusted,
            certErrorQuery: certErrorExpired,
            expectedCertError: certErrorExpired
        )
    }

    @MainActor
    func testResponseForErrorWebPage_withBadDateErrorWithoutCertErrorQuery_usesExpiredFallback() {
        assertErrorPageContainsCertError(
            networkErrorCode: NSURLErrorServerCertificateHasBadDate,
            certErrorQuery: nil,
            expectedCertError: certErrorExpired
        )
    }

    @MainActor
    func testLoadPage_withCertificateErrorWithoutUnderlyingError_stillAddsCertErrorQuery() throws {
        let subject = ErrorPageHelper(certStore: nil)
        let webView = MockTabWebView(
            frame: .zero,
            configuration: WKWebViewConfiguration(),
            windowUUID: .XCTestDefaultUUID,
            certStore: MockProfile().certStore
        )
        let failingURL = URL(string: "https://expired.badssl.com/")!
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted)

        subject.loadPage(error, forUrl: failingURL, inWebView: webView)

        let loadedURL = try XCTUnwrap(webView.loadedRequest?.url)
        let components = URLComponents(url: loadedURL, resolvingAgainstBaseURL: false)
        let certError = components?.queryItems?.first(where: { $0.name == certErrorQueryParam })?.value
        XCTAssertEqual(certError, certErrorUnknownIssuer)
    }

    @MainActor
    func testLoadPage_withOfflineErrorAndRestrictedCellularData_showsCellularDataGuidance() throws {
        let subject = ErrorPageHelper(
            certStore: nil,
            cellularDataStateProvider: MockCellularDataStateProvider(isRestricted: true)
        )
        let webView = MockTabWebView(
            frame: .zero,
            configuration: WKWebViewConfiguration(),
            windowUUID: .XCTestDefaultUUID,
            certStore: MockProfile().certStore
        )
        let failingURL = URL(string: "https://example.com/")!
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSURLErrorFailingURLErrorKey: failingURL]
        )

        subject.loadPage(error, forUrl: failingURL, inWebView: webView)

        let loadedURL = try XCTUnwrap(webView.loadedRequest?.url)
        let components = URLComponents(url: loadedURL, resolvingAgainstBaseURL: false)
        XCTAssertEqual(
            components?.queryItems?.first(where: { $0.name == "cellularDataRestricted" })?.value,
            "true"
        )

        let response = ErrorPageHandler().responseForErrorWebPage(request: URLRequest(url: loadedURL))
        let html = try XCTUnwrap(response.flatMap { String(data: $0.1, encoding: .utf8) })
        XCTAssertTrue(html.contains(String.NativeErrorPage.CellularDataRestricted.TitleLabel))
        XCTAssertTrue(html.contains(String.NativeErrorPage.CellularDataRestricted.Description))
    }

    @MainActor
    func testLoadPage_withOfflineErrorAndAvailableCellularData_keepsDefaultErrorPage() throws {
        let subject = ErrorPageHelper(
            certStore: nil,
            cellularDataStateProvider: MockCellularDataStateProvider(isRestricted: false)
        )
        let webView = MockTabWebView(
            frame: .zero,
            configuration: WKWebViewConfiguration(),
            windowUUID: .XCTestDefaultUUID,
            certStore: MockProfile().certStore
        )
        let failingURL = URL(string: "https://example.com/")!
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSURLErrorFailingURLErrorKey: failingURL]
        )

        subject.loadPage(error, forUrl: failingURL, inWebView: webView)

        let loadedURL = try XCTUnwrap(webView.loadedRequest?.url)
        let components = URLComponents(url: loadedURL, resolvingAgainstBaseURL: false)
        XCTAssertNil(components?.queryItems?.first(where: { $0.name == "cellularDataRestricted" }))
    }
}

private extension ErrorPageHandlerTests {
    var certErrorQueryParam: String { "certerror" }
    var certErrorExpired: String { "SEC_ERROR_EXPIRED_CERTIFICATE" }
    var certErrorUnknownIssuer: String { "SEC_ERROR_UNKNOWN_ISSUER" }

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
            urlString += "&\(certErrorQueryParam)=\(certErrorQuery)"
        }
        return URL(string: urlString)!
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation
import WebKit
@testable import Client

class DownloadHelperTests: XCTestCase {
    func test_init_whenMIMETypeIsNil_initializeCorrectly() {
        let response = anyResponse(mimeType: nil)

        var subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)
        XCTAssertNotNil(subject)

        subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: true)
        XCTAssertNotNil(subject)

        subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: false)
        XCTAssertNotNil(subject)

        subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: true)
        XCTAssertNotNil(subject)
    }

    func test_init_whenMIMETypeIsNotOctetStream_initializeCorrectly() {
        for mimeType in allMIMETypes() {
            if mimeType == MIMEType.OctetStream { continue }

            let response = anyResponse(mimeType: mimeType)

            var subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)
            XCTAssertNil(subject)

            subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: true)
            XCTAssertNotNil(subject)

            subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: false)
            XCTAssertNotNil(subject)

            subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: true)
            XCTAssertNotNil(subject)
        }
    }

    func test_init_whenMIMETypeIsOctetStream_initializeCorrectly() {
        let response = anyResponse(mimeType: MIMEType.OctetStream)

        var subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)
        XCTAssertNotNil(subject)

        subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: true)
        XCTAssertNotNil(subject)

        subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: true)
        XCTAssertNotNil(subject)

        subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: false, forceDownload: false)
        XCTAssertNotNil(subject)
    }

    func test_downloadViewModel_whenRequestURLIsWrong_deliversEmptyResult() {
        let request = anyRequest(urlString: "wrong-url.com")
        let subject = DownloadHelper(request: request, response: anyResponse(mimeType: nil), cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)

        let downloadViewModel = subject?.downloadViewModel(okAction: { _ in })

        XCTAssertNil(downloadViewModel)
    }

    func test_downloadViewModel_deliversCorrectTitle() {
        let response = anyResponse(urlString: "http://some-domain.com/some-image.jpg")
        let subject = DownloadHelper(request: anyRequest(), response: response, cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)

        let downloadViewModel = subject?.downloadViewModel(okAction: { _ in })

        XCTAssertEqual(downloadViewModel!.title!, "some-image.jpg")
    }

    func test_downloadViewModel_deliversCorrectCancelButtonTitle() {
        let subject = DownloadHelper(request: anyRequest(), response: anyResponse(mimeType: nil), cookieStore: cookieStore(), canShowInWebView: true, forceDownload: false)

        let downloadViewModel = subject?.downloadViewModel(okAction: { _ in })

        XCTAssertEqual(downloadViewModel!.closeButtonTitle, .CancelString)
    }

    // MARK: - Helpers

    private func anyRequest(urlString: String = "http://any-url.com") -> URLRequest {
        return URLRequest(url: URL(string: urlString)!, cachePolicy: anyCachePolicy(), timeoutInterval: 60.0)
    }

    private func anyResponse(mimeType: String?) -> URLResponse {
        return URLResponse(url: URL(string: "http://any-url.com")!, mimeType: mimeType, expectedContentLength: 10, textEncodingName: nil)
    }

    private func anyResponse(urlString: String) -> URLResponse {
        return URLResponse(url: URL(string: urlString)!, mimeType: nil, expectedContentLength: 10, textEncodingName: nil)
    }

    private func cookieStore() -> WKHTTPCookieStore {
        return WKWebsiteDataStore.`default`().httpCookieStore
    }

    private func anyCachePolicy() -> URLRequest.CachePolicy {
        return .useProtocolCachePolicy
    }

    private func allMIMETypes() -> [String] {
        return [MIMEType.Bitmap,
                MIMEType.CSS,
                MIMEType.GIF,
                MIMEType.JavaScript,
                MIMEType.JPEG,
                MIMEType.HTML,
                MIMEType.OctetStream,
                MIMEType.Passbook,
                MIMEType.PDF,
                MIMEType.PlainText,
                MIMEType.PNG,
                MIMEType.WebP,
                MIMEType.Calendar,
                MIMEType.USDZ,
                MIMEType.Reality]
    }
}

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

        let subject = createSubject(request: anyRequest(),
                                    response: response,
                                    cookieStore: cookieStore())
        XCTAssertNotNil(subject)
    }

    func test_shouldDownloadFile_whenMIMETypeOctetStream_isTrue() {
        let mimeType = MIMEType.OctetStream

        let response = anyResponse(mimeType: mimeType)
        let subject = createSubject(request: anyRequest(),
                                    response: response,
                                    cookieStore: cookieStore())
        let shouldDownload = subject?.shouldDownloadFile(canShowInWebView: true,
                                                         forceDownload: false,
                                                         isForMainFrame: false)
        XCTAssertTrue(shouldDownload ?? false)
    }

    func test_shouldDownloadFile_whenMIMETypeIsNotOctetStream_isFalse() {
        let mimeType = MIMEType.GIF

        let response = anyResponse(mimeType: mimeType)
        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertFalse(shouldDownload)
        }
    }

    func test_shouldDownloadFile_whenCanShowInWebview_isFalse() {
        let response = anyResponse(mimeType: MIMEType.GIF)

        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertFalse(shouldDownload)
        }
    }

    func test_shouldDownloadFile_whenCanNotShowInWebview_isTrue() {
        let response = anyResponse(mimeType: MIMEType.GIF)

        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: false,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertTrue(shouldDownload)
        }
    }

    func test_shouldDownloadFile_whenNotForceDownload_isFalse() {
        let response = anyResponse(mimeType: MIMEType.GIF)

        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertFalse(shouldDownload)
        }
    }

    func test_shouldDownloadFile_whenForceDownload_isTrue() {
        let response = anyResponse(mimeType: MIMEType.GIF)

        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: false,
                                                            forceDownload: true,
                                                            isForMainFrame: false)
            XCTAssertTrue(shouldDownload)
        }
    }

    func test_downloadViewModel_whenRequestURLIsWrong_deliversEmptyResult() {
        let request = anyRequest(urlString: "wrong-url.com")
        let subject = createSubject(request: request,
                                    response: anyResponse(mimeType: nil),
                                    cookieStore: cookieStore())

        let downloadViewModel = subject?.downloadViewModel(windowUUID: .XCTestDefaultUUID, okAction: { _ in })

        XCTAssertNil(downloadViewModel)
    }

    func test_downloadViewModel_deliversCorrectTitle() {
        let response = anyResponse(urlString: "http://some-domain.com/some-image.jpg")
        let subject = createSubject(request: anyRequest(),
                                    response: response,
                                    cookieStore: cookieStore())

        let downloadViewModel = subject?.downloadViewModel(windowUUID: .XCTestDefaultUUID, okAction: { _ in })

        XCTAssertEqual(downloadViewModel!.title!, "some-image.jpg")
    }

    func test_downloadViewModel_deliversCorrectCancelButtonTitle() {
        let subject = createSubject(request: anyRequest(),
                                    response: anyResponse(mimeType: nil),
                                    cookieStore: cookieStore())

        let downloadViewModel = subject?.downloadViewModel(windowUUID: .XCTestDefaultUUID, okAction: { _ in })

        XCTAssertEqual(downloadViewModel!.closeButtonTitle, .CancelString)
    }

    // MARK: - Helpers

    private func createSubject(request: URLRequest,
                               response: URLResponse,
                               cookieStore: WKHTTPCookieStore) -> DownloadHelper? {
        return DownloadHelper(request: request,
                              response: response,
                              cookieStore: cookieStore)
    }

    private func anyRequest(urlString: String = "http://any-url.com") -> URLRequest {
        return URLRequest(url: URL(string: urlString)!, cachePolicy: anyCachePolicy(), timeoutInterval: 60.0)
    }

    private func anyResponse(mimeType: String?) -> URLResponse {
        return URLResponse(
            url: URL(string: "http://any-url.com")!,
            mimeType: mimeType,
            expectedContentLength: 10,
            textEncodingName: nil
        )
    }

    private func anyResponse(urlString: String) -> URLResponse {
        return URLResponse(
            url: URL(string: urlString)!,
            mimeType: nil,
            expectedContentLength: 10,
            textEncodingName: nil
        )
    }

    private func cookieStore() -> WKHTTPCookieStore {
        return WKWebsiteDataStore.`default`().httpCookieStore
    }

    private func anyCachePolicy() -> URLRequest.CachePolicy {
        return .useProtocolCachePolicy
    }
}

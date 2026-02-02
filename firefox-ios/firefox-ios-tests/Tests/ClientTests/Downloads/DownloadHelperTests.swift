// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation
import WebKit
@testable import Client

class DownloadHelperTests: XCTestCase {
    @MainActor
    func test_init_whenMIMETypeIsNil_initializeCorrectly() {
        let response = anyResponse(mimeType: nil)

        let subject = createSubject(request: anyRequest(),
                                    response: response,
                                    cookieStore: cookieStore())
        XCTAssertNotNil(subject)
    }

    @MainActor
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

    @MainActor
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

    @MainActor
    func test_shouldDownloadFile_whenContentDispositionAttachmentHeader_isTrue() {
        let response = httpURLResponse(mimeType: MIMEType.JPEG,
                                       contentDispositionHeader: true)
        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertTrue(shouldDownload)
        }
    }

    @MainActor
    func test_shouldDownloadFile_whenContentDispositionAttachmentHeader_isFalse() {
        let response = httpURLResponse(mimeType: MIMEType.JPEG,
                                       contentDispositionHeader: false)
        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertFalse(shouldDownload)
        }
    }

    @MainActor
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

    @MainActor
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

    @MainActor
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

    @MainActor
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

    @MainActor
    func test_downloadViewModel_whenRequestURLIsWrong_deliversEmptyResult() {
        let request = anyRequest(urlString: "wrong-url.com")
        let subject = createSubject(request: request,
                                    response: anyResponse(mimeType: nil),
                                    cookieStore: cookieStore())

        let downloadViewModel = subject?.downloadViewModel(windowUUID: .XCTestDefaultUUID, okAction: { _ in })

        XCTAssertNil(downloadViewModel)
    }

    @MainActor
    func test_downloadViewModel_deliversCorrectTitle() {
        let response = anyResponse(urlString: "http://some-domain.com/some-image.jpg")
        let subject = createSubject(request: anyRequest(),
                                    response: response,
                                    cookieStore: cookieStore())

        let downloadViewModel = subject?.downloadViewModel(windowUUID: .XCTestDefaultUUID, okAction: { _ in })

        XCTAssertEqual(downloadViewModel!.title!, "some-image.jpg")
    }

    @MainActor
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

    private func httpURLResponse(mimeType: String,
                                 contentDispositionHeader: Bool) -> MockHTTPURLResponse {
        return MockHTTPURLResponse(forcedMimeType: mimeType,
                                   url: URL(string: "http://any-url.com")!,
                                   statusCode: 200,
                                   httpVersion: "HTTP/1.1",
                                   headerFields: contentDispositionHeader ? ["Content-Disposition": "attachment"] : nil)!
    }

    private func anyResponse(urlString: String) -> URLResponse {
        return URLResponse(
            url: URL(string: urlString)!,
            mimeType: nil,
            expectedContentLength: 10,
            textEncodingName: nil
        )
    }

    @MainActor
    private func cookieStore() -> WKHTTPCookieStore {
        return WKWebsiteDataStore.`default`().httpCookieStore
    }

    private func anyCachePolicy() -> URLRequest.CachePolicy {
        return .useProtocolCachePolicy
    }
}

class MockHTTPURLResponse: HTTPURLResponse, @unchecked Sendable {
    private var forcedMimeType: String
    init?(forcedMimeType: String,
          url: URL,
          statusCode: Int,
          httpVersion HTTPVersion: String?,
          headerFields: [String: String]?) {
        self.forcedMimeType = forcedMimeType
        super.init(url: url,
                   statusCode: statusCode,
                   httpVersion: HTTPVersion,
                   headerFields: headerFields)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var mimeType: String? { forcedMimeType }
}

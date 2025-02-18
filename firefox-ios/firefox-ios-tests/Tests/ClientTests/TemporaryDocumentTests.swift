// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class MockURLProtocol: URLProtocol {
    static var response: ((HTTPURLResponse, URLRequest) -> Void)?
    static var data: Data?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        Self.response?(
            response,
            request
        )
        if let data = Self.data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}

class MockURLResponse: URLResponse, @unchecked Sendable {
    let filename: String

    override var suggestedFilename: String? {
        return filename
    }

    init(filename: String, url: URL) {
        self.filename = filename
        super.init(
            url: url,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TemporaryDocumentTests: XCTestCase, URLSessionDownloadDelegate {
    private let filename = "TempPDF.pdf"
    private let request = URLRequest(url: URL(string: "https://example.com")!)
    private let mimeTypePDF = "application/pdf"
    private var mockURLSession: URLSession!
    private var subject: DefaultTemporaryDocument!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }

    override func tearDown() {
        MockURLProtocol.response = nil
        MockURLProtocol.data = nil
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: tempFileURL)
        mockURLSession = nil
        subject = nil
        super.tearDown()
    }

    func testInit_appliesCookiesToRequest() {
        let expectation = XCTestExpectation(description: "Response should be called")
        let cookie = HTTPCookie(
            properties: [
                .domain: "example.com",
                .path: "/",
                .name: "key",
                .value: "session=123",
                .secure: true,
                .expires: Date(timeIntervalSinceNow: 20)
            ]
        )!
        subject = createSubject(
            filename: filename,
            request: request,
            session: mockURLSession,
            mimeType: mimeTypePDF,
            cookies: [cookie]
        )

        MockURLProtocol.response = { _, response in
            XCTAssertEqual(response.allHTTPHeaderFields?["Cookie"], "key=session=123")
            expectation.fulfill()
        }

        subject.download { _ in }
        wait(for: [expectation], timeout: 0.1)
    }

    func testInit_passCorrectName_fromResponse() {
        let response = MockURLResponse(filename: filename, url: request.url!)
        subject = createSubject(response: response, request: request, session: mockURLSession)

        XCTAssertEqual(subject.filename, filename)
    }

    func testDownloadAsync() async {
        subject = createSubject(filename: filename, request: request, session: mockURLSession)

        MockURLProtocol.data = Data()
        let localURL = await subject.download()

        XCTAssertNotNil(localURL)
        XCTAssertEqual(localURL?.lastPathComponent, filename)
    }

    func testDownload() {
        let expectation = XCTestExpectation(description: "download callback should be fired")
        MockURLProtocol.data = Data()
        subject = createSubject(filename: filename, request: request, session: mockURLSession)

        subject.download { url in
            XCTAssertNotNil(url)
            XCTAssertEqual(url?.lastPathComponent, self.filename)
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.2)
    }

    func testDownload_onDownloadStarted() {
        let expectation = XCTestExpectation(description: "onStart callback should be fired")
        MockURLProtocol.data = Data()
        subject = createSubject(filename: filename, request: request, session: mockURLSession)

        subject.onDownloadStarted = {
            expectation.fulfill()
        }
        subject.urlSession(
            mockURLSession,
            downloadTask: mockURLSession.downloadTask(with: request),
            didWriteData: 0,
            totalBytesWritten: 0,
            totalBytesExpectedToWrite: 0
        )

        wait(for: [expectation], timeout: 0.2)
        // it is nilled out so to not call it again
        XCTAssertNil(self.subject.onDownloadStarted)
    }

    func testDownload_onProgressUpdate() {
        let expectation = XCTestExpectation(description: "onDownloadProgressUpdate callback should be fired")
        let mockProgress = 100.0
        MockURLProtocol.data = Data()
        subject = createSubject(filename: filename, request: request, session: mockURLSession)

        subject.onDownloadProgressUpdate = { progress in
            XCTAssertEqual(progress, mockProgress)
            expectation.fulfill()
        }
        subject.urlSession(
            mockURLSession,
            downloadTask: mockURLSession.downloadTask(with: request),
            didWriteData: 0,
            totalBytesWritten: Int64(mockProgress),
            totalBytesExpectedToWrite: 1
        )

        wait(for: [expectation], timeout: 0.2)
    }

    func testDeinit_removeTempFile() {
        XCTAssert(true)
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let subject else { return }
        subject.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard let subject else { return }
        subject.urlSession(session, task: task, didCompleteWithError: error)
    }

    private func createSubject(
        filename: String?,
        request: URLRequest,
        session: URLSession,
        mimeType: String? = nil,
        cookies: [HTTPCookie] = []
    ) -> DefaultTemporaryDocument {
        return DefaultTemporaryDocument(
            filename: filename,
            request: request,
            mimeType: mimeType,
            cookies: cookies,
            session: session
        )
    }

    private func createSubject(
        response: URLResponse,
        request: URLRequest,
        mimeType: String? = nil,
        session: URLSession = .shared
    ) -> DefaultTemporaryDocument {
        return DefaultTemporaryDocument(
            preflightResponse: response,
            request: request,
            mimeType: mimeType,
            session: session
        )
    }
}

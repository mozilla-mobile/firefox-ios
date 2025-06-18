// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TemporaryDocumentTests: XCTestCase {
    private let filename = "TempPDF.pdf"
    private let request = URLRequest(url: URL(string: "https://example.com")!)
    private let mimeTypePDF = "application/pdf"
    private var mockURLSession: URLSession!
    private var subject: DefaultTemporaryDocument!
    private var mockURLProtocol: MockURLProtocol!

    override func setUp() {
        super.setUp()
        mockURLProtocol = MockURLProtocol()

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]

        mockURLSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        mockURLProtocol.response = nil
        mockURLProtocol.data = nil
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: tempFileURL)
        mockURLSession = nil
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

        mockURLProtocol.response = { _, response in
            XCTAssertEqual(response.allHTTPHeaderFields?["Cookie"], "key=session=123")
        }

        subject.download { _ in
            expectation.fulfill()
        }
        wait(for: [expectation])

        subject = nil
    }

    func testInit_passCorrectName_fromResponse() {
        let response = MockURLResponse(filename: filename, url: request.url!)
        subject = createSubject(response: response, request: request, session: mockURLSession)

        XCTAssertEqual(subject.filename, filename)
        subject = nil
    }

    func testDownloadAsync() async {
        subject = createSubject(filename: filename, request: request, session: mockURLSession)

        mockURLProtocol.data = Data()
        let localURL = await subject.download()

        XCTAssertNotNil(localURL)
        XCTAssertEqual(localURL?.lastPathComponent, filename)
        subject = nil
    }

    func testDownload() {
        let expectation = XCTestExpectation(description: "download callback should be fired")
        mockURLProtocol.data = Data()
        subject = createSubject(filename: filename, request: request, session: mockURLSession)

        subject.download { [weak self] url in
            XCTAssertNotNil(url)
            XCTAssertEqual(url?.lastPathComponent, self?.filename)
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        wait(for: [expectation])

        subject.cancelDownload()
        subject = nil
    }

    func testDownload_onDownloadStarted() {
        let expectation = XCTestExpectation(description: "onStart callback should be fired")
        mockURLProtocol.data = Data()
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

        wait(for: [expectation])
        // it is nilled out so to not call it again
        XCTAssertNil(self.subject.onDownloadStarted)
        subject = nil
    }

    func testDownload_onProgressUpdate() {
        let expectation = XCTestExpectation(description: "onDownloadProgressUpdate callback should be fired")
        let mockProgress = 100.0
        mockURLProtocol.data = Data()
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

        wait(for: [expectation])

        subject = nil
    }

    func testDeinit_removeTempFile_whenPDFRefactorDisabled() async throws {
        setIsPDFRefactorFeature(isEnabled: false)
        subject = createSubject(filename: filename, request: request, session: mockURLSession, mimeType: mimeTypePDF)
        let url = try await unwrapAsync {
            return await subject.download()
        }

        subject = nil

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testDeinit_doesNotRemoveTempPDFFile_whenPDFRefactorEnabled() async throws {
        setIsPDFRefactorFeature(isEnabled: true)
        // Make sure is a PDF, otherwise it falls back to remove the file
        subject = createSubject(filename: filename, request: request, session: mockURLSession, mimeType: mimeTypePDF)
        let url = try await unwrapAsync {
            return await subject.download()
        }

        subject = nil

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    private func createSubject(
        filename: String?,
        request: URLRequest,
        session: URLSession,
        mimeType: String? = nil,
        cookies: [HTTPCookie] = []
    ) -> DefaultTemporaryDocument {
        let subject = DefaultTemporaryDocument(
            filename: filename,
            request: request,
            mimeType: mimeType,
            cookies: cookies,
            session: session
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func createSubject(
        response: URLResponse,
        request: URLRequest,
        mimeType: String? = nil,
        session: URLSession
    ) -> DefaultTemporaryDocument {
        let subject = DefaultTemporaryDocument(
            preflightResponse: response,
            request: request,
            mimeType: mimeType,
            session: session
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setIsPDFRefactorFeature(isEnabled: Bool) {
        FxNimbus.shared.features.pdfRefactorFeature.with { _, _ in
            PdfRefactorFeature(enabled: isEnabled)
        }
    }
}

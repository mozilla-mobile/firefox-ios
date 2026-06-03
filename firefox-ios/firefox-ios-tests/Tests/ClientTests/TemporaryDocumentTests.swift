// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class TemporaryDocumentTests: XCTestCase, @unchecked Sendable {
    private let filename = "TempPDF.pdf"
    private let request = URLRequest(url: URL(string: "https://example.com")!)
    private let mimeTypePDF = "application/pdf"
    private var mockURLSession: URLSession!
    private var subject: DefaultTemporaryDocument!
    private var mockURLProtocol: MockURLProtocol!

    override func setUp() async throws {
        try await super.setUp()
        mockURLProtocol = MockURLProtocol()

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]

        mockURLSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
    }

    override func tearDown() async throws {
        mockURLProtocol.response = nil
        mockURLProtocol.data = nil
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: tempFileURL)
        mockURLSession = nil
        try await super.tearDown()
    }

    func testInit_appliesCookiesToRequest() async {
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
        subject = await createSubject(
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
        await fulfillment(of: [expectation])

        subject = nil
    }

    // MARK: - Cookie Domain Tests

    func testCookieDomainMatches_exactDomain_matches() {
        let cookie = makeCookie(domain: "example.com")
        XCTAssertTrue(DefaultTemporaryDocument.cookieDomainMatches(cookie, url: URL(string: "https://example.com")!))
    }

    func testCookieDomainMatches_hostOnlyCookie_doesNotMatchSubdomain() {
        // RFC 6265 Section 5.4 specifies that host-only-flag=true requires identical host, not subdomain match
        // https://www.rfc-editor.org/rfc/rfc6265#section-5.4
        // no leading dot = host-only (no Domain attribute). This means it must NOT match subdomain
        let hostOnlyCookie = makeCookie(domain: "example.com")
        XCTAssertFalse(DefaultTemporaryDocument.cookieDomainMatches(hostOnlyCookie, url: URL(string: "https://evil.example.com")!))
        // leading dot = domain-scoped (explicit Domain attribute). This means subdomain match IS expected
        let domainScopedCookie = makeCookie(domain: ".example.com")
        XCTAssertTrue(DefaultTemporaryDocument.cookieDomainMatches(domainScopedCookie, url: URL(string: "https://evil.example.com")!))
    }

    func testCookieDomainMatches_substringDomain_doesNotMatch() {
        // Request to azon.com should not match amazon.com's cookie, even though
        // "azon.com" is a substring of "amazon.com".
        let cookie = makeCookie(domain: "amazon.com")
        XCTAssertFalse(DefaultTemporaryDocument.cookieDomainMatches(cookie, url: URL(string: "https://azon.com")!))
    }

    func testCookieDomainMatches_unrelatedDomain_doesNotMatch() {
        let cookie = makeCookie(domain: "example.com")
        XCTAssertFalse(DefaultTemporaryDocument.cookieDomainMatches(cookie, url: URL(string: "https://othersite.com")!))
    }

    func testCookieDomainMatches_isCaseInsensitive() {
        let cookie = makeCookie(domain: "Example.COM")
        XCTAssertTrue(DefaultTemporaryDocument.cookieDomainMatches(cookie, url: URL(string: "https://EXAMPLE.com")!))
    }

    func testCookieDomainMatches_siblingSubdomain_doesNotMatch() {
        let cookie = makeCookie(domain: "subdomain1.example.com")
        XCTAssertFalse(DefaultTemporaryDocument.cookieDomainMatches(cookie, url: URL(string: "https://subdomain2.example.com")!))
    }

    // MARK: - Redirect Cookie Tests

    func testWillPerformHTTPRedirection_crossOrigin_stripsCookies() async {
        let cookie = makeCookie(domain: "example.com")
        subject = await createSubject(
            filename: filename, request: request, session: mockURLSession, mimeType: mimeTypePDF, cookies: [cookie]
        )
        var redirect = URLRequest(url: URL(string: "https://evil.com/x.pdf")!)
        redirect.setValue("key=session=123", forHTTPHeaderField: "Cookie")

        let result = performRedirect(on: subject, to: redirect)

        XCTAssertEqual(result?.allHTTPHeaderFields?["Cookie"], "")
        subject = nil
    }

    func testWillPerformHTTPRedirection_sameHost_keepsCookies() async {
        let cookie = makeCookie(domain: "example.com")
        subject = await createSubject(
            filename: filename, request: request, session: mockURLSession, mimeType: mimeTypePDF, cookies: [cookie]
        )
        let redirect = URLRequest(url: URL(string: "https://example.com/x.pdf")!)

        let result = performRedirect(on: subject, to: redirect)

        XCTAssertEqual(result?.allHTTPHeaderFields?["Cookie"], "key=session=123")
        subject = nil
    }

    func testWillPerformHTTPRedirection_noCookies_passesRequestThrough() async {
        subject = await createSubject(filename: filename, request: request, session: mockURLSession, mimeType: mimeTypePDF)
        var redirect = URLRequest(url: URL(string: "https://evil.com/x.pdf")!)
        redirect.setValue("injected=value", forHTTPHeaderField: "Cookie")

        let result = performRedirect(on: subject, to: redirect)

        XCTAssertEqual(result?.allHTTPHeaderFields?["Cookie"], "injected=value")
        subject = nil
    }

    func testInit_passCorrectName_fromResponse() async {
        let response = MockURLResponse(filename: filename, url: request.url!)
        subject = await createSubject(response: response, request: request, session: mockURLSession)

        XCTAssertEqual(subject.filename, filename)
        subject = nil
    }

    func testDownloadAsync() async {
        subject = await createSubject(filename: filename, request: request, session: mockURLSession)

        mockURLProtocol.data = Data()
        let localURL = await subject.download()

        XCTAssertNotNil(localURL)
        XCTAssertEqual(localURL?.lastPathComponent, filename)
        subject = nil
    }

    func testDownload() async {
        let expectation = XCTestExpectation(description: "download callback should be fired")
        mockURLProtocol.data = Data()
        subject = await createSubject(filename: filename, request: request, session: mockURLSession)

        subject.download { [filename] url in
            XCTAssertNotNil(url)
            XCTAssertEqual(url?.lastPathComponent, filename)
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation])

        subject.cancelDownload()
        subject = nil
    }

    func testDownload_onDownloadStarted() async {
        let expectation = XCTestExpectation(description: "onStart callback should be fired")
        mockURLProtocol.data = Data()
        subject = await createSubject(filename: filename, request: request, session: mockURLSession)

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

        await fulfillment(of: [expectation])
        // it is nilled out so to not call it again
        XCTAssertNil(self.subject.onDownloadStarted)
        subject = nil
    }

    func testDownload_onProgressUpdate() async {
        let expectation = XCTestExpectation(description: "onDownloadProgressUpdate callback should be fired")
        let mockProgress = 100.0
        mockURLProtocol.data = Data()
        subject = await createSubject(filename: filename, request: request, session: mockURLSession)

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

        await fulfillment(of: [expectation])

        subject = nil
    }

    func testDeinit_removeTempFile_whenFileIsNotPDF() async throws {
        subject = await createSubject(
            filename: "test.json",
            request: request,
            session: mockURLSession,
            mimeType: "application/json"
        )
        let url = try await unwrapAsync {
            return await subject.download()
        }

        subject = nil

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testDeinit_doesNotRemoveTempPDFFile() async throws {
        // Make sure is a PDF, otherwise it falls back to remove the file
        subject = await createSubject(filename: filename, request: request, session: mockURLSession, mimeType: mimeTypePDF)
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
    ) async -> DefaultTemporaryDocument {
        let subject = DefaultTemporaryDocument(
            filename: filename,
            request: request,
            mimeType: mimeType,
            cookies: cookies,
            session: session
        )
        await trackForMemoryLeaks(subject)
        return subject
    }

    private func createSubject(
        response: URLResponse,
        request: URLRequest,
        mimeType: String? = nil,
        session: URLSession
    ) async -> DefaultTemporaryDocument {
        let subject = DefaultTemporaryDocument(
            preflightResponse: response,
            request: request,
            mimeType: mimeType,
            session: session
        )
        await trackForMemoryLeaks(subject)
        return subject
    }

    private func performRedirect(on subject: DefaultTemporaryDocument, to newRequest: URLRequest) -> URLRequest? {
        let response = HTTPURLResponse(url: request.url!, statusCode: 307, httpVersion: nil, headerFields: nil)!
        var result: URLRequest?
        subject.urlSession(
            mockURLSession,
            task: mockURLSession.downloadTask(with: newRequest),
            willPerformHTTPRedirection: response,
            newRequest: newRequest
        ) { result = $0 }
        return result
    }

    private func makeCookie(domain: String) -> HTTPCookie {
        return HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: "key",
            .value: "session=123"
        ])!
    }
}

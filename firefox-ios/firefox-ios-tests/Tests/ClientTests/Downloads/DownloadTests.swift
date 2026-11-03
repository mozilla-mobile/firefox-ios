// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

@MainActor
final class DownloadTests: XCTestCase {
    var download: Download!

    override func setUp() async throws {
        try await super.setUp()
        download = Download(originWindow: .XCTestDefaultUUID)
    }

    override func tearDown() async throws {
        download = nil
        try await super.tearDown()
    }

    func testDelegateMemoryLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate
        trackForMemoryLeaks(download, file: #filePath, line: #line)
        download = nil
    }

    func testCancelDoesNotLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate

        // Simulate canceling the download
        download.cancel()

        // Check for memory leaks
        trackForMemoryLeaks(download, file: #filePath, line: #line)

        download = nil
    }

    func testPauseDoesNotLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate

        // Simulate pausing the download
        download.pause()

        // Check for memory leaks
        trackForMemoryLeaks(download, file: #filePath, line: #line)

        download = nil
    }

    func testResumeDoesNotLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate

        // Simulate resuming the download
        download.resume()

        // Check for memory leaks
        trackForMemoryLeaks(download, file: #filePath, line: #line)

        download = nil
    }
}

@MainActor
final class HTTPDownloadTests: XCTestCase {
    private let testURL = URL(string: "https://example.com/file.pdf")!

    func testInit_doesNotCreateSession() throws {
        let download = try createSubject()

        XCTAssertNil(download.session)
        XCTAssertNil(download.task)
    }

    func testInitWithoutResume_releasesDownload() throws {
        weak var weakDownload: HTTPDownload?
        try autoreleasepool {
            let download = try createSubject()
            weakDownload = download
        }

        waitForDeallocation({ weakDownload })
    }

    func testResume_createsSessionLazily() throws {
        let download = try createSubject()
        XCTAssertNil(download.session)

        download.resume()

        let session = try waitForSession(afterResuming: download)
        XCTAssertNotNil(download.task)

        let task = try XCTUnwrap(download.task)
        task.cancel()
        download.urlSession(session, task: task, didCompleteWithError: nil)
    }

    func testCancel_releasesDownload() throws {
        weak var weakDownload: HTTPDownload?
        try autoreleasepool {
            let download = try createSubject()
            weakDownload = download
            download.cancel()
        }

        waitForDeallocation({ weakDownload })
    }

    func testCompletion_releasesDownload() throws {
        weak var weakDownload: HTTPDownload?
        try autoreleasepool {
            let download = try createSubject()
            weakDownload = download
            download.resume()
            // resume() creates the session lazily and asynchronously
            // (after the cookie store round-trip).
            let session = try waitForSession(afterResuming: download)
            let task = try XCTUnwrap(download.task)
            // Cancel the task so the session has no outstanding work,
            // matching a real download whose task already reached a terminal state.
            task.cancel()
            download.urlSession(session, task: task, didCompleteWithError: nil)
        }

        waitForDeallocation({ weakDownload })
    }

    private func createSubject() throws -> HTTPDownload {
        let response = try XCTUnwrap(HTTPURLResponse(url: testURL,
                                                     statusCode: 200,
                                                     httpVersion: nil,
                                                     headerFields: nil))
        return try XCTUnwrap(HTTPDownload(originWindow: .XCTestDefaultUUID,
                                          cookieStore: WKWebsiteDataStore.default().httpCookieStore,
                                          preflightResponse: response,
                                          request: URLRequest(url: testURL)))
    }

    private func waitForSession(afterResuming download: HTTPDownload,
                                timeout: TimeInterval = 10,
                                file: StaticString = #filePath,
                                line: UInt = #line) throws -> URLSession {
        let created = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in download.session != nil },
            object: nil
        )
        wait(for: [created], timeout: timeout)
        return try XCTUnwrap(download.session,
                             "resume() should lazily create the session",
                             file: file,
                             line: line)
    }

    /// The session releases its delegate asynchronously on its delegate queue (main),
    /// so poll instead of asserting right away.
    private func waitForDeallocation(_ object: @escaping () -> AnyObject?,
                                     timeout: TimeInterval = 10,
                                     file: StaticString = #filePath,
                                     line: UInt = #line) {
        let released = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in autoreleasepool { object() == nil } },
            object: nil
        )
        wait(for: [released], timeout: timeout)
        XCTAssertNil(object(),
                     "HTTPDownload should deallocate once its session is invalidated",
                     file: file,
                     line: line)
    }
}

// MARK: - DownloadDelegate Methods
class MockDownloadDelegate: DownloadDelegate {
    // Called when the download is complete
    func download(_ download: Download, didCompleteWithError error: Error?) { }

    // Called when a certain amount of bytes have been downloaded
    func download(_ download: Download, didDownloadBytes bytesDownloaded: Int64) { }

    // Called when the download finishes and provides the location of the downloaded file
    func download(_ download: Download, didFinishDownloadingTo location: URL) { }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class DownloadTests: XCTestCase {
    var download: Download!

    override func setUp() {
        super.setUp()
        download = Download()
    }

    override func tearDown() {
        super.tearDown()
        download = nil
    }

    func testDelegateMemoryLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate
        trackForMemoryLeaks(download, file: #file, line: #line)
        download = nil
    }

    func testCancelDoesNotLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate

        // Simulate canceling the download
        download.cancel()

        // Check for memory leaks
        trackForMemoryLeaks(download, file: #file, line: #line)

        download = nil
    }

    func testPauseDoesNotLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate

        // Simulate pausing the download
        download.pause()

        // Check for memory leaks
        trackForMemoryLeaks(download, file: #file, line: #line)

        download = nil
    }

    func testResumeDoesNotLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate

        // Simulate resuming the download
        download.resume()

        // Check for memory leaks
        trackForMemoryLeaks(download, file: #file, line: #line)

        download = nil
    }
}

class MockDownloadDelegate: DownloadDelegate {
    func download(_ download: Download, didCompleteWithError error: Error?) { }
    func download(_ download: Download, didDownloadBytes bytesDownloaded: Int64) { }
    func download(_ download: Download, didFinishDownloadingTo location: URL) { }
}

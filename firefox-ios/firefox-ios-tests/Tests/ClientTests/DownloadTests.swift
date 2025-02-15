// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class DownloadTests: XCTestCase {
    var download: Download!

    override func setUp() {
        super.setUp()
        download = Download(originWindow: .XCTestDefaultUUID)
    }

    override func tearDown() {
        download = nil
        super.tearDown()
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

// MARK: - DownloadDelegate Methods
class MockDownloadDelegate: DownloadDelegate {
    // Called when the download is complete
    func download(_ download: Download, didCompleteWithError error: Error?) { }

    // Called when a certain amount of bytes have been downloaded
    func download(_ download: Download, didDownloadBytes bytesDownloaded: Int64) { }

    // Called when the download finishes and provides the location of the downloaded file
    func download(_ download: Download, didFinishDownloadingTo location: URL) { }
}

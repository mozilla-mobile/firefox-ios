// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest

class DownloadTests: XCTestCase {
    
    var download: Download!
    
    override func setUp() {
        download = Download()
    }
    
    override func tearDown() {
        download = nil
    }
    
    func testDelegateMemoryLeak() {
        let mockDownloadDelegate = MockDownloadDelegate()
        download.delegate = mockDownloadDelegate
        trackForMemoryLeaks(download)
        download = nil
    }
}

class MockDownloadDelegate: DownloadDelegate {
    func download(_ download: Client.Download, didCompleteWithError error: Error?) { }
    
    func download(_ download: Client.Download, didDownloadBytes bytesDownloaded: Int64) { }
    
    func download(_ download: Client.Download, didFinishDownloadingTo location: URL) { }
}

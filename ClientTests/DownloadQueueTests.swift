/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import XCTest

class DownloadQueueTests: XCTestCase {
    
    let didStartDownload = "downloadQueue(_:didStartDownload:)"
    let didDownloadCombinedBytes = "downloadQueue(_:didDownloadCombinedBytes:combinedTotalBytesExpected:)"
    let didCompleteWithError = "downloadQueue(_:didCompleteWithError:)"
    let didFinishDownloadingTo = "downloadQueue(_:download:didFinishDownloadingTo:)"
    
    var queue: DownloadQueue!
    var download: MockDownload!
    
    override func setUp() {
        queue = DownloadQueue()
        download = MockDownload()
        
        super.setUp()
    }
    
    func testDownloadQueueIsEmpty() {
        XCTAssertTrue(queue.isEmpty)
    }
    
    func testDownloadQueueIsNotEmpty() {
        queue.downloads = [download]
        XCTAssertTrue(!queue.isEmpty)
    }
    
    func testEnqueueDownloadShouldAppendDownloadAndTriggerResume() {
        queue.enqueueDownload(download)
        XCTAssertTrue(download.downloadTriggered)
    }
    
    func testEnqueueDownloadShouldCallDownloadQueueDidStartDownload() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.delegate = mockQueueDelegate
        queue.enqueueDownload(download)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didStartDownload)
    }
    
    func testCancelAllDownload() {
        queue.downloads = [download]
        queue.cancelAllDownloads()
        XCTAssertTrue(download.downloadCanceled)
    }
    
    func testDidDownloadBytes() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.delegate = mockQueueDelegate
        queue.downloads = [download]
        queue.download(download, didDownloadBytes: 0)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didDownloadCombinedBytes)
    }
    
    func testDidFinishDownloadingToWithOneElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.delegate = mockQueueDelegate
        queue.downloads = [download]
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didCompleteWithError)
    }
    
    func testDidFinishDownloadingToWithTwoElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.delegate = mockQueueDelegate
        queue.downloads = [download, MockDownload()]
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didFinishDownloadingTo)
    }
    
    func testDidFinishDownloadingToWithNoElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.delegate = mockQueueDelegate
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, "noneOfMethodWasCalled")
    }
    
    func testDidCompleteWithError() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.delegate = mockQueueDelegate
        queue.downloads = [download]
        queue.download(download, didCompleteWithError: DownloadTestError.NoError("OK"))
        XCTAssertEqual(mockQueueDelegate.methodCalled, didCompleteWithError)
    }

}

private enum DownloadTestError: Error {
    case NoError(String)
}

private let url = URL(string: "http://mozilla.org")!

class MockDownload: Download {
    var downloadTriggered: Bool = false
    var downloadCanceled: Bool = false

    override func resume() {
        downloadTriggered = true
    }
    
    override func cancel() {
        downloadCanceled = true
    }
    
    init() {
        let urlRequest = URLRequest(url: url)
        let urlResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        
        super.init(preflightResponse: urlResponse, request: urlRequest)
    }
    
}

class MockDownloadQueueDelegate: DownloadQueueDelegate {
    var methodCalled: String = "noneOfMethodWasCalled"
    
    func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download) {
        methodCalled = #function
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, didDownloadCombinedBytes combinedBytesDownloaded: Int64, combinedTotalBytesExpected: Int64?) {
        methodCalled = #function
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL) {
        methodCalled = #function
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?) {
        methodCalled = #function
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import Common

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

    override func tearDown() {
        super.tearDown()
        queue = nil
        download = nil
    }

    func testDownloadQueueIsEmpty() {
        XCTAssertTrue(queue.isEmpty)
    }

    func testDownloadQueueIsNotEmpty() {
        queue.downloads = [download]
        XCTAssertTrue(!queue.isEmpty)
    }

    func testEnqueueDownloadShouldAppendDownloadAndTriggerResume() {
        queue.enqueue(download)
        XCTAssertTrue(download.downloadTriggered)
    }

    func testEnqueueDownloadShouldCallDownloadQueueDidStartDownload() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.enqueue(download)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didStartDownload)
    }

    func testCancelAllDownload() {
        queue.downloads = [download]
        queue.cancelAll(for: .XCTestDefaultUUID)
        XCTAssertTrue(download.downloadCanceled)
    }

    func testDidDownloadBytes() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.downloads = [download]
        queue.download(download, didDownloadBytes: 0)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didDownloadCombinedBytes)
    }

    func testDidFinishDownloadingToWithOneElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.downloads = [download]
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didCompleteWithError)
    }

    func testDidFinishDownloadingToWithTwoElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.downloads = [download, MockDownload(originWindow: WindowUUID.XCTestDefaultUUID)]
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didFinishDownloadingTo)
    }

    func testDidFinishDownloadingToWithNoElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, "noneOfMethodWasCalled")
    }

    func testDidCompleteWithError() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.downloads = [download]
        queue.download(download, didCompleteWithError: DownloadTestError.noError("OK"))
        XCTAssertEqual(mockQueueDelegate.methodCalled, didCompleteWithError)
    }

    func testDelegateMemoryLeak() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        trackForMemoryLeaks(queue)
        queue = nil
    }
}

private enum DownloadTestError: Error {
    case noError(String)
}

private let url = URL(string: "http://mozilla.org")!

class MockDownloadQueueDelegate: DownloadQueueDelegate {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    var methodCalled = "noneOfMethodWasCalled"

    func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download) {
        methodCalled = #function
    }

    func downloadQueue(
        _ downloadQueue: DownloadQueue,
        didDownloadCombinedBytes combinedBytesDownloaded: Int64,
        combinedTotalBytesExpected: Int64?
    ) {
        methodCalled = #function
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL) {
        methodCalled = #function
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?) {
        methodCalled = #function
    }
}

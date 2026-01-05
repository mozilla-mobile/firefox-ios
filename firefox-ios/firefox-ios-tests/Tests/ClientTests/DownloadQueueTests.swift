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
        super.setUp()
        queue = DownloadQueue()
        download = MockDownload()
    }

    override func tearDown() {
        queue = nil
        download = nil
        super.tearDown()
    }

    func testDownloadQueueIsEmpty() {
        XCTAssertTrue(queue.isEmpty)
    }

    func testDownloadQueueIsNotEmpty() {
        queue.downloads = [download]
        XCTAssertTrue(!queue.isEmpty)
    }

    @MainActor
    func testEnqueueDownloadShouldAppendDownloadAndTriggerResume() {
        queue.enqueue(download)
        XCTAssertTrue(download.downloadTriggered)
    }

    @MainActor
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

    @MainActor
    func testDidDownloadBytes() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.downloads = [download]
        queue.download(download, didDownloadBytes: 0)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didDownloadCombinedBytes)
    }

    @MainActor
    func testDidFinishDownloadingToWithOneElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.downloads = [download]
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didCompleteWithError)
    }

    @MainActor
    func testDidFinishDownloadingToWithTwoElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.downloads = [download, MockDownload(originWindow: WindowUUID.XCTestDefaultUUID)]
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, didFinishDownloadingTo)
    }

    @MainActor
    func testDidFinishDownloadingToWithNoElementsInQueue() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.download(download, didFinishDownloadingTo: url)
        XCTAssertEqual(mockQueueDelegate.methodCalled, "noneOfMethodWasCalled")
    }

    @MainActor
    func testDidCompleteWithError() {
        let mockQueueDelegate = MockDownloadQueueDelegate()
        queue.addDelegate(mockQueueDelegate)
        queue.downloads = [download]
        queue.download(download, didCompleteWithError: DownloadTestError.noError("OK"))
        XCTAssertEqual(mockQueueDelegate.methodCalled, didCompleteWithError)
    }

    @MainActor
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

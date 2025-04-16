// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client
import Common

class DownloadProgressManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testSingleDownloadIntialization() {
        let download = MockDownload()
        let downloadProgressManager = createSubject(downloads: [download])
        XCTAssertEqual(downloadProgressManager.combinedTotalBytesExpected, download.totalBytesExpected)
        XCTAssertEqual(downloadProgressManager.combinedBytesDownloaded, download.bytesDownloaded)
    }

    func testAddingContentEncodedDownload() {
        let download = MockDownload(totalBytesExpected: nil)
        let download2 = MockDownload()
        let downloadProgressManager = createSubject(downloads: [download])
        let mockDelegate = MockDownloadProgressDelegate()

        downloadProgressManager.addDelegate(delegate: mockDelegate)

        downloadProgressManager.addDownload(download2)

        XCTAssertEqual(mockDelegate.didCallUpdateCombinedTotalBytesExpectedCount, 1)
        XCTAssertNil(downloadProgressManager.combinedTotalBytesExpected)
    }

    func testAddingMultipleDownloads() {
        let download = MockDownload()
        let download2 = MockDownload()
        let downloadProgressManager = createSubject(downloads: [download])
        let mockDelegate = MockDownloadProgressDelegate()

        downloadProgressManager.addDelegate(delegate: mockDelegate)

        downloadProgressManager.addDownload(download2)

        XCTAssertEqual(mockDelegate.didCallUpdateCombinedTotalBytesExpectedCount, 1)
        XCTAssertEqual(mockDelegate.totalBytesExpectedParameter, 40)
    }

    @available(iOS 16.2, *)
    func testMemoryLeaks() {
        let download = MockDownload()
        let downloadProgressManager = createSubject(downloads: [download])
        var downloadLiveActivity: DownloadLiveActivityWrapper? = DownloadLiveActivityWrapper(
            downloadProgressManager: downloadProgressManager)
        var downloadToast: DownloadToast? = DownloadToast(
            downloadProgressManager: downloadProgressManager,
            theme: LightTheme(),
            completion: { _ in })

        downloadProgressManager.addDelegate(delegate: downloadLiveActivity!)
        downloadProgressManager.addDelegate(delegate: downloadToast!)

        downloadLiveActivity = nil
        downloadToast = nil

        let expectation = XCTestExpectation(description: "Wait for 0.5 seconds")

            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                self.trackForMemoryLeaks(downloadProgressManager)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
    }

    func createSubject(downloads: [Download]) -> DownloadProgressManager {
        return DownloadProgressManager(downloads: downloads)
    }
}

class MockDownloadProgressDelegate: DownloadProgressDelegate {
    var didCallUpdateCombinedBytesDownloadedCount = 0
    var didCallUpdateCombinedTotalBytesExpectedCount = 0
    var bytesDownloadedParameter: Int64 = 0
    var totalBytesExpectedParameter: Int64?

    func updateCombinedBytesDownloaded(value: Int64) {
        didCallUpdateCombinedBytesDownloadedCount += 1
        bytesDownloadedParameter = value
    }

    func updateCombinedTotalBytesExpected(value: Int64?) {
        didCallUpdateCombinedTotalBytesExpectedCount += 1
        totalBytesExpectedParameter = value
    }
}

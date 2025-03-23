// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WidgetKit

@testable import Client

class DownloadLiveActivityAttributesTests: XCTestCase {
    func testContentStateComputedProperties() {
        let download1 = makeDownload(type: DownloadType.normal, isComplete: true)
        let download2 = makeDownload(type: DownloadType.contentEncoded, isComplete: true)
        let download3 = makeDownload(type: DownloadType.nilExpectedBytes, isComplete: false)
        let download4 = makeDownload(type: DownloadType.normal, totalBytesExpected: nil, isComplete: false)
        let contentState = DownloadLiveActivityAttributes.ContentState(
            downloads: [download1, download2, download3, download4]
        )

        XCTAssertEqual(contentState.completedDownloads, 2)
        XCTAssertEqual(contentState.totalDownloads, 4)
    }

    func testGetDownloadProgress() {
        let bytesDownloaded1: Int64 = 500
        let bytesDownloaded2: Int64 = 300
        let totalBytesExpected1: Int64 = 1000
        let totalBytesExpected2: Int64 = 2000
        let download1 = makeDownload(
            type: DownloadType.normal,
            bytesDownloaded: bytesDownloaded1,
            totalBytesExpected: totalBytesExpected1,
            isComplete: true
        )
        let download2 = makeDownload(
            type: DownloadType.normal,
            bytesDownloaded: bytesDownloaded2,
            totalBytesExpected: totalBytesExpected2,
            isComplete: false
        )
        let download3 = makeDownload(
            type: DownloadType.contentEncoded,
            bytesDownloaded: 100,
            totalBytesExpected: 100,
            isComplete: true
        )
        let download4 = makeDownload(
            type: DownloadType.nilExpectedBytes,
            bytesDownloaded: 100,
            totalBytesExpected: 100,
            isComplete: false
        )
        let contentState = DownloadLiveActivityAttributes.ContentState(
            downloads: [download1, download2, download3, download4]
        )
        let expectedProgress =
            Double(bytesDownloaded1 + bytesDownloaded2) / Double(totalBytesExpected1 + totalBytesExpected2)

        // download 3 and download 4 progress should be ignored
        XCTAssertEqual(contentState.totalProgress, expectedProgress)
        XCTAssertEqual(contentState.totalBytesExpected, totalBytesExpected1 + totalBytesExpected2)
        XCTAssertEqual(contentState.totalBytesDownloaded, bytesDownloaded1 + bytesDownloaded2)
    }

    func testGetDownloadProgressNoEstimate() {
        let download1 = makeDownload(type: DownloadType.contentEncoded)
        let download2 = makeDownload(type: DownloadType.nilExpectedBytes)
        let contentState = DownloadLiveActivityAttributes.ContentState(
            downloads: [download1, download2]
        )

        XCTAssertEqual(contentState.totalProgress, 0)
        XCTAssertEqual(contentState.totalBytesExpected, 0)
        XCTAssertEqual(contentState.totalBytesDownloaded, 0)
    }

    func testGetTotalProgressWhenNoDownloads() {
        let contentState = DownloadLiveActivityAttributes.ContentState(downloads: [])

        XCTAssertEqual(contentState.totalProgress, 0)
        XCTAssertEqual(contentState.totalDownloads, 0)
        XCTAssertEqual(contentState.completedDownloads, 0)
    }

    // MARK: - Helper Methods

    enum DownloadType {
        case normal
        case contentEncoded
        case nilExpectedBytes
    }

    private func makeDownload(
        type: DownloadType,
        fileName: String = "file",
        bytesDownloaded: Int64 = 100,
        totalBytesExpected: Int64? = 100,
        isComplete: Bool = false
    ) -> DownloadLiveActivityAttributes.ContentState.Download {
        DownloadLiveActivityAttributes.ContentState.Download(
            fileName: fileName,
            hasContentEncoding: type == DownloadType.contentEncoded,
            totalBytesExpected: type == DownloadType.nilExpectedBytes ? nil : totalBytesExpected,
            bytesDownloaded: bytesDownloaded,
            isComplete: isComplete
        )
    }
}

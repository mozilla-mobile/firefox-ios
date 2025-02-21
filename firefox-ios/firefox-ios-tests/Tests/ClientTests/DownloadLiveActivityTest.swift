// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WidgetKit

@testable import Client

class DownloadLiveActivityTest: XCTestCase {
    let download1 = DownloadLiveActivityAttributes.ContentState.Download(
        id: UUID(),
        fileName: "file1",
        mimeType: "application/pdf",
        hasContentEncoding: true,
        downloadPath: URL(string: "https://example.com/file1")!,
        totalBytesExpected: 1000,
        bytesDownloaded: 1000,
        isComplete: true
    )
    let download2 = DownloadLiveActivityAttributes.ContentState.Download(
        id: UUID(),
        fileName: "file2",
        mimeType: "application/pdf",
        hasContentEncoding: nil,
        downloadPath: URL(string: "https://example.com/file2")!,
        totalBytesExpected: 1000,
        bytesDownloaded: 500,
        isComplete: false
    )
    let download3 = DownloadLiveActivityAttributes.ContentState.Download(
        id: UUID(),
        fileName: "file3",
        mimeType: "application/pdf",
        hasContentEncoding: nil,
        downloadPath: URL(string: "https://example.com/file3")!,
        totalBytesExpected: 500,
        bytesDownloaded: 500,
        isComplete: true
    )
    let download4 = DownloadLiveActivityAttributes.ContentState.Download(
        id: UUID(),
        fileName: "file4",
        mimeType: "application/pdf",
        hasContentEncoding: nil,
        downloadPath: URL(string: "https://example.com/file4")!,
        totalBytesExpected: nil,
        bytesDownloaded: 500,
        isComplete: false
    )

    func testContentStateComputedProperties() {
        let contentState = DownloadLiveActivityAttributes.ContentState(
            downloads: [download1, download2, download3, download4]
        )

        XCTAssertEqual(contentState.completedDownloads, 2)
        XCTAssertEqual(contentState.totalDownloads, 4)
    }

    func testGetDownloadProgress() {
        let contentState = DownloadLiveActivityAttributes.ContentState(
            downloads: [download1, download2, download3, download4]
        )
        let expectedProgress = (500 + 500) / (1000 + 1000)

        // download 1 and download 4 progress should be ignored
        XCTAssertEqual(contentState.getTotalProgress(), expectedProgress)
    }

    func testGetDownloadProgressNoEstimate() {
        let contentState = DownloadLiveActivityAttributes.ContentState(
            downloads: [download1, download4]
        )

        // download 1 and download 4 progress should be ignored
        XCTAssertEqual(contentState.getTotalProgress(), 0)
    }

    func testGetTotalProgressWhenNoDownloads() {
        let contentState = DownloadLiveActivityAttributes.ContentState(downloads: [])

        XCTAssertEqual(contentState.getTotalProgress(), 0)
    }
}

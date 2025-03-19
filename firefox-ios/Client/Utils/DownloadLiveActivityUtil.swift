// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Foundation
import WidgetKit

typealias DownloadState = DownloadLiveActivityAttributes.ContentState.Download

// TODO: FXIOS-11619 investigate ways to move DownloadLiveActivityUtil code into DownloadLiveActivityAttributes
struct DownloadLiveActivityUtil {
    static func generateDownloadStateFromDownload(download: Download) -> DownloadState {
        let downloadState = DownloadState(
            fileName: download.filename,
            hasContentEncoding: download.hasContentEncoding,
            totalBytesExpected: download.totalBytesExpected,
            bytesDownloaded: download.bytesDownloaded,
            isComplete: download.isComplete)
        return downloadState
    }

    static func buildContentState(downloads: [Download]) -> [DownloadState] {
        let downloadsStates = downloads.map({ download in generateDownloadStateFromDownload(download: download) })
        return downloadsStates
    }
}

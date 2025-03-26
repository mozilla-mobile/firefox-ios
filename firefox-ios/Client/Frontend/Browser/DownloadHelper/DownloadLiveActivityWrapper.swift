// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WidgetKit
import ActivityKit
import Common
import Shared

@available(iOS 16.2, *)
class DownloadLiveActivityWrapper: DownloadProgressDelegate {
    enum DurationToDismissal: Double {
        case none = 0
        case delayed = 2
    }
    var downloadLiveActivity: Activity<DownloadLiveActivityAttributes>?

    var downloadProgressManager: DownloadProgressManager

    init(downloadProgressManager: DownloadProgressManager) {
        self.downloadProgressManager = downloadProgressManager
    }

    func start() -> Bool {
        let attributes = DownloadLiveActivityAttributes()

        let downloadsStates = DownloadLiveActivityUtil.buildContentState(downloads: downloadProgressManager.downloads)
        let contentState = DownloadLiveActivityAttributes.ContentState(downloads: downloadsStates)

        do {
            downloadLiveActivity = try Activity<DownloadLiveActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            return true
        } catch {
            return false
        }
    }

    func end(durationToDismissal: DurationToDismissal) {
        let downloadsStates = DownloadLiveActivityUtil.buildContentState(downloads: downloadProgressManager.downloads)
        let contentState = DownloadLiveActivityAttributes.ContentState(downloads: downloadsStates)
        Task {
            await downloadLiveActivity?.end(using: contentState,
                                            dismissalPolicy: .after(.now.addingTimeInterval(durationToDismissal.rawValue)))
        }
    }
}

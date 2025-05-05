// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WidgetKit
import ActivityKit
import Common
import Shared

@available(iOS 17, *)
class DownloadLiveActivityWrapper: DownloadProgressDelegate {
    private struct UX {
        static let updateCooldown = 0.75 // Update Cooldown in Seconds
    }

    enum DurationToDismissal: UInt64 {
        case none = 0
        case delayed = 3_000_000_000 // Milliseconds to dismissal
    }

    let throttler = ConcurrencyThrottler(seconds: UX.updateCooldown)

    var downloadLiveActivity: Activity<DownloadLiveActivityAttributes>?

    var downloadProgressManager: DownloadProgressManager

    let windowUUID: String

    init(downloadProgressManager: DownloadProgressManager, windowUUID: String) {
        self.downloadProgressManager = downloadProgressManager
        self.windowUUID = windowUUID
    }

    func start() -> Bool {
        let attributes = DownloadLiveActivityAttributes(windowUUID: windowUUID)

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
        Task {
            let downloadsStates = DownloadLiveActivityUtil.buildContentState(downloads: downloadProgressManager.downloads)
            let contentState = DownloadLiveActivityAttributes.ContentState(downloads: downloadsStates)
            await update()
            try await Task.sleep(nanoseconds: durationToDismissal.rawValue)
            await downloadLiveActivity?.end(using: contentState, dismissalPolicy: .immediate)
        }
    }

    private func update() async {
        let downloadsStates = DownloadLiveActivityUtil.buildContentState(downloads: downloadProgressManager.downloads)
        let contentState = DownloadLiveActivityAttributes.ContentState(downloads: downloadsStates)
        await self.downloadLiveActivity?.update(using: contentState)
    }

    func updateCombinedBytesDownloaded(value: Int64) {
        throttler.throttle {
            Task {
                await self.update()
            }
        }
    }

    func updateCombinedTotalBytesExpected(value: Int64?) {
        throttler.throttle {
            Task {
                await self.update()
            }
        }
    }
}

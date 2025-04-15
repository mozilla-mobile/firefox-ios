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
        static let updateCooldown: TimeInterval = 0.75
    }

    enum DurationToDismissal: UInt64 {
        case none = 0
        case delayed = 3_000_000_000 // Milliseconds to dismissal
    }

    private var lastUpdateTime = Date.distantPast

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
        let downloadsStates = DownloadLiveActivityUtil.buildContentState(downloads: downloadProgressManager.downloads)
        let contentState = DownloadLiveActivityAttributes.ContentState(downloads: downloadsStates)
        update(throttle: false)
        Task {
            try await Task.sleep(nanoseconds: durationToDismissal.rawValue)
            await downloadLiveActivity?.end(using: contentState, dismissalPolicy: .immediate)
        }
    }

    private func shouldUpdateLiveActivity() -> Bool {
        let currentTime = Date()
        
        guard currentTime.timeIntervalSince(lastUpdateTime) >= UX.updateCooldown else {return false}
        lastUpdateTime = currentTime
        return true
    }

    private func update(throttle: Bool = true) {
        let downloadsStates = DownloadLiveActivityUtil.buildContentState(downloads: downloadProgressManager.downloads)
        let contentState = DownloadLiveActivityAttributes.ContentState(downloads: downloadsStates)
        if !throttle || shouldUpdateLiveActivity() {
            Task {
                    await self.downloadLiveActivity?.update(using: contentState)
            }
        }
    }

    func updateCombinedBytesDownloaded(value: Int64) {
        update()
    }

    func updateCombinedTotalBytesExpected(value: Int64?) {
        update()
    }
}

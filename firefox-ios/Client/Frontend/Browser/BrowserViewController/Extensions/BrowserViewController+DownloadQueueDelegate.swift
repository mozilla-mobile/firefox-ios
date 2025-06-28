// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

extension BrowserViewController: DownloadQueueDelegate {
    func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download) {
        // For now, each window handles its downloads independently; ignore any messages for 'other windows' downloads.
        let uuid = windowUUID
        guard downloadQueue.windowUUID == uuid else { return }

        // Do not need toast message for Passbook Passes since we don't save the download
        guard download.mimeType != MIMEType.Passbook else { return }

        // Do not need toast message for Mobile Config files since we don't save the download
        guard download.mimeType != MIMEType.MobileConfig else { return }

        if let downloadProgressManager = self.downloadProgressManager {
            if tabManager.selectedTab?.isPrivate == true {
                dismissDownloadLiveActivity()
            }
            downloadProgressManager.addDownload(download)
            return
        }

        let downloadProgressManager = DownloadProgressManager(downloads: [download])
        self.downloadProgressManager = downloadProgressManager

        if #available(iOS 17, *),
           featureFlags.isFeatureEnabled(.downloadLiveActivities, checking: .buildOnly),
           tabManager.selectedTab?.isPrivate == false {
            let downloadLiveActivityWrapper = DownloadLiveActivityWrapper(
                downloadProgressManager: downloadProgressManager,
                windowUUID: windowUUID.uuidString)
            downloadProgressManager.addDelegate(delegate: downloadLiveActivityWrapper)
            self.downloadLiveActivityWrapper = downloadLiveActivityWrapper
            guard downloadLiveActivityWrapper.start() else {
                self.downloadLiveActivityWrapper = nil
                return
            }
        }
        presentDownloadProgressToast(download: download, windowUUID: uuid)
    }

    private func dismissDownloadLiveActivity() {
        if #available(iOS 17, *),
           featureFlags.isFeatureEnabled(.downloadLiveActivities, checking: .buildOnly),
           let downloadLiveActivityWrapper = self.downloadLiveActivityWrapper {
            downloadLiveActivityWrapper.end(durationToDismissal: .none)
            self.downloadLiveActivityWrapper = nil
        }
    }
}


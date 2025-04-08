// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

extension BrowserViewController: DownloadQueueDelegate {
    func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download) {
        // For now, each window handles its downloads independently; ignore any messages for other windows' downloads.
        let uuid = windowUUID
        guard download.originWindow == uuid else { return }

        // Do not need toast message for Passbook Passes since we don't save the download
        guard download.mimeType != MIMEType.Passbook else { return }

        if let downloadProgressManager = self.downloadProgressManager {
            downloadProgressManager.addDownload(download)
            return
        }

        let downloadProgressManager = DownloadProgressManager(downloads: [download])
        self.downloadProgressManager = downloadProgressManager

        if #available(iOS 16.2, *), featureFlags.isFeatureEnabled(.downloadLiveActivities, checking: .buildOnly) {
            let downloadLiveActivityWrapper = DownloadLiveActivityWrapper(downloadProgressManager: downloadProgressManager)
            downloadProgressManager.addDelegate(delegate: downloadLiveActivityWrapper)
            self.downloadLiveActivityWrapper = downloadLiveActivityWrapper
            guard downloadLiveActivityWrapper.start() else {
                self.downloadLiveActivityWrapper = nil
                return
            }
        }
        presentDownloadProgressToast(download: download, windowUUID: uuid)
    }

    func stopDownload(buttonPressed: Bool) {
        // When this toast is dismissed, be sure to clear this so that any
        // subsequent downloads cause a new toast to be created.
        self.downloadToast = nil
        if #available(iOS 16.2, *),
           featureFlags.isFeatureEnabled(.downloadLiveActivities, checking: .buildOnly),
            let downloadLiveActivityWrapper = self.downloadLiveActivityWrapper {
            downloadLiveActivityWrapper.end(durationToDismissal: .none)
            self.downloadLiveActivityWrapper = nil
        }
        self.downloadProgressManager = nil

        // Handle download cancellation
        if buttonPressed, !downloadQueue.isEmpty {
            downloadQueue.cancelAll(for: windowUUID)

            SimpleToast().showAlertWithText(.DownloadCancelledToastLabelText,
                                            bottomContainer: self.contentContainer,
                                            theme: self.currentTheme())
        }
    }

    func downloadQueue(
        _ downloadQueue: DownloadQueue,
        didDownloadCombinedBytes combinedBytesDownloaded: Int64,
        combinedTotalBytesExpected: Int64?
    ) {
        downloadProgressManager?.combinedBytesDownloaded = combinedBytesDownloaded
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL) {
        // Handle Passbook Pass downloads
        if let download = (download as? BlobDownload),
           OpenPassBookHelper.shouldOpenWithPassBook(mimeType: download.mimeType) {
            passBookHelper = OpenPassBookHelper(presenter: self)
            passBookHelper?.open(data: download.data) {
                self.passBookHelper = nil
            }
        }

        // Handle toast notification
        guard let downloadToast = self.downloadToast,
              let downloadProgressManager = self.downloadProgressManager,
              let download = downloadProgressManager.downloads.first,
              download.originWindow == windowUUID, downloadQueue.isEmpty
        else { return }

        DispatchQueue.main.async { [weak self] in
            downloadToast.dismiss(false)
            if #available(iOS 16.2, *), let downloadLiveActivityWrapper = self?.downloadLiveActivityWrapper {
                downloadLiveActivityWrapper.end(durationToDismissal: .delayed)
                self?.downloadLiveActivityWrapper = nil
            }
            self?.downloadProgressManager = nil
            self?.presentDownloadCompletedToast(filename: download.filename)
        }
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?) {
        guard let downloadToast = self.downloadToast,
              let downloadProgressManager = self.downloadProgressManager,
              let download = downloadProgressManager.downloads.first,
              download.originWindow == windowUUID
        else { return }

        // We only care about download errors specific to our window's downloads
        DispatchQueue.main.async {
            downloadToast.dismiss(false)
            if #available(iOS 16.2, *),
               let downloadLiveActivityWrapper = self.downloadLiveActivityWrapper {
                downloadLiveActivityWrapper.end(durationToDismissal: .delayed)
                self.downloadLiveActivityWrapper = nil
            }
            self.downloadProgressManager = nil

            if error != nil {
                SimpleToast().showAlertWithText(.DownloadCancelledToastLabelText,
                                                bottomContainer: self.contentContainer,
                                                theme: self.currentTheme())
            }
        }
    }

    func presentDownloadProgressToast(download: Download, windowUUID: WindowUUID) {
        guard let downloadProgressManager = self.downloadProgressManager else {return}
        let downloadToast = DownloadToast(downloadProgressManager: downloadProgressManager,
                                          theme: currentTheme(),
                                          completion: { buttonPressed in
            self.stopDownload(buttonPressed: buttonPressed)})

        downloadProgressManager.addDelegate(delegate: downloadToast)

        show(toast: downloadToast, duration: nil)
    }

    func presentDownloadCompletedToast(filename: String) {
        let viewModel = ButtonToastViewModel(labelText: filename,
                                             imageName: StandardImageIdentifiers.Large.checkmark,
                                             buttonText: .DownloadsButtonTitle)
        let downloadCompleteToast = ButtonToast(viewModel: viewModel,
                                                theme: self.currentTheme(),
                                                completion: { buttonPressed in
            guard buttonPressed else { return }

            self.showLibrary(panel: .downloads)
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .view,
                object: .downloadsPanel,
                value: .downloadCompleteToast
            )
        })

        self.show(toast: downloadCompleteToast,
                  afterWaiting: UX.downloadToastDelay,
                  duration: UX.downloadToastDuration)
    }
}

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

        // If no other download toast is shown, create a new download toast and show it.
        guard let downloadToast = self.downloadToast else {
            presentDownloadProgressToast(download: download, windowUUID: uuid)
            return
        }

        // Otherwise, just add this download to the existing download toast.
        downloadToast.addDownload(download)
    }

    func downloadQueue(
        _ downloadQueue: DownloadQueue,
        didDownloadCombinedBytes combinedBytesDownloaded: Int64,
        combinedTotalBytesExpected: Int64?
    ) {
        downloadToast?.combinedBytesDownloaded = combinedBytesDownloaded
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL) {
        guard let downloadToast = self.downloadToast,
              let download = downloadToast.downloads.first,
              download.originWindow == windowUUID, downloadQueue.isEmpty
        else { return }

        DispatchQueue.main.async { [weak self] in
                downloadToast.dismiss(false)
                self?.presentDownloadCompletedToast(filename: download.filename)
        }
    }

    func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?) {
        guard let downloadToast = self.downloadToast,
              let download = downloadToast.downloads.first,
              download.originWindow == windowUUID
        else { return }

        // We only care about download errors specific to our window's downloads
        DispatchQueue.main.async {
            downloadToast.dismiss(false)

            if error != nil {
                SimpleToast().showAlertWithText(.DownloadCancelledToastLabelText,
                                                bottomContainer: self.contentContainer,
                                                theme: self.currentTheme())
            }
        }
    }

    func presentDownloadProgressToast(download: Download, windowUUID: WindowUUID) {
        let downloadToast = DownloadToast(download: download,
                                          theme: currentTheme(),
                                          completion: { buttonPressed in
            // When this toast is dismissed, be sure to clear this so that any
            // subsequent downloads cause a new toast to be created.
            self.downloadToast = nil

            // Handle download cancellation
            if buttonPressed, !self.downloadQueue.isEmpty {
                self.downloadQueue.cancelAll(for: windowUUID)

                SimpleToast().showAlertWithText(.DownloadCancelledToastLabelText,
                                                bottomContainer: self.contentContainer,
                                                theme: self.currentTheme())
            }
        })

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

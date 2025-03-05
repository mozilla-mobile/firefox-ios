// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

protocol DownloadQueueDelegate: AnyObject {
    var windowUUID: WindowUUID { get }
    func downloadQueue(_ downloadQueue: DownloadQueue, didStartDownload download: Download)
    func downloadQueue(
        _ downloadQueue: DownloadQueue,
        didDownloadCombinedBytes combinedBytesDownloaded: Int64,
        combinedTotalBytesExpected: Int64?
    )
    func downloadQueue(_ downloadQueue: DownloadQueue, download: Download, didFinishDownloadingTo location: URL)
    func downloadQueue(_ downloadQueue: DownloadQueue, didCompleteWithError error: Error?)
}

class WeakDownloadQueueDelegate {
    private(set) weak var delegate: DownloadQueueDelegate?
    init(delegate: DownloadQueueDelegate? = nil) { self.delegate = delegate }
}

struct DownloadProgress {
    var bytesDownloaded: Int64
    var totalExpected: Int64
}

class DownloadQueue: DownloadDelegate {
    var downloads: [Download]

    private var delegates = [WeakDownloadQueueDelegate]()

    var isEmpty: Bool {
        return downloads.isEmpty
    }

    fileprivate var downloadProgress: [WindowUUID: DownloadProgress] = [:]
    fileprivate var downloadErrors: [WindowUUID: Error] = [:]

    init() {
        self.downloads = []
    }

    func addDelegate(_ delegate: DownloadQueueDelegate) {
        self.cleanUpDelegates()
        delegates.append(WeakDownloadQueueDelegate(delegate: delegate))
    }

    func removeDelegate(_ delegate: DownloadQueueDelegate) {
        delegates.removeAll(where: { $0.delegate === delegate || $0.delegate == nil })
    }

    func enqueue(_ download: Download) {
        // Clear the download stats if the queue was empty at the start.
        let uuid = download.originWindow
        if downloads(for: uuid).isEmpty {
            downloadProgress[uuid] = nil
            downloadErrors[uuid] = nil
        }

        downloads.append(download)
        download.delegate = self

        if let totalBytesExpected = download.totalBytesExpected {
            var progress = downloadProgress[uuid] ?? DownloadProgress(bytesDownloaded: 0, totalExpected: 0)
            progress.totalExpected += totalBytesExpected
            downloadProgress[uuid] = progress
        } else {
            downloadProgress[uuid] = nil
        }

        download.resume()
        delegates.forEach { $0.delegate?.downloadQueue(self, didStartDownload: download) }
    }

    func cancelAll(for window: WindowUUID) {
        for download in downloads where !download.isComplete && download.originWindow == window {
            download.cancel()
        }
    }

    func pauseAll(for window: WindowUUID) {
        for download in downloads where !download.isComplete && download.originWindow == window {
            download.pause()
        }
    }

    func resumeAll(for window: WindowUUID) {
        for download in downloads where !download.isComplete && download.originWindow == window {
            download.resume()
        }
    }

    // MARK: - Utility

    private func cleanUpDelegates() {
        delegates.removeAll(where: { $0.delegate == nil })
    }

    private func downloads(for window: WindowUUID) -> [Download] {
        return downloads.filter({ $0.originWindow == window })
    }

    // MARK: - DownloadDelegate
    func download(_ download: Download, didCompleteWithError error: Error?) {
        guard let error = error, let index = downloads.firstIndex(of: download) else { return }

        let uuid = download.originWindow
        downloadErrors[uuid] = error
        downloads.remove(at: index)

        // If all downloads for the completed download's window are completed, we notify of error
        if downloads(for: uuid).isEmpty {
            delegates.forEach {
                guard $0.delegate?.windowUUID == uuid else { return }
                $0.delegate?.downloadQueue(self, didCompleteWithError: error)
            }
        }
    }

    func download(_ download: Download, didDownloadBytes bytesDownloaded: Int64) {
        let uuid = download.originWindow
        var progress = downloadProgress[uuid] ?? DownloadProgress(bytesDownloaded: 0, totalExpected: 0)
        progress.bytesDownloaded += bytesDownloaded
        downloadProgress[uuid] = progress

        delegates.forEach {
            guard $0.delegate?.windowUUID == uuid else { return }
            $0.delegate?.downloadQueue(self,
                                       didDownloadCombinedBytes: progress.bytesDownloaded,
                                       combinedTotalBytesExpected: progress.totalExpected)
        }
    }

    func download(_ download: Download, didFinishDownloadingTo location: URL) {
        guard let index = downloads.firstIndex(of: download) else { return }

        downloads.remove(at: index)
        delegates.forEach { $0.delegate?.downloadQueue(self, download: download, didFinishDownloadingTo: location) }

        NotificationCenter.default.post(name: .FileDidDownload, object: location)

        // If all downloads for the completed download's window are completed, we notify of completion
        let uuid = download.originWindow
        if downloads(for: uuid).isEmpty {
            let error = downloadErrors[uuid]
            delegates.forEach {
                guard $0.delegate?.windowUUID == uuid else { return }
                $0.delegate?.downloadQueue(self, didCompleteWithError: error)
            }
            downloadErrors[uuid] = nil
        }
    }
}

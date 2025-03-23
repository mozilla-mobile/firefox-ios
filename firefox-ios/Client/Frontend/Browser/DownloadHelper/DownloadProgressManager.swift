// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
protocol DownloadProgressDelegate: AnyObject {
    func updateCombinedBytesDownloaded(value: Int64)

    func updateCombinedTotalBytesExpected(value: Int64?)
}

extension DownloadProgressDelegate {
    func updateCombinedBytesDownloaded(value: Int64) {}

    func updateCombinedTotalBytesExpected(value: Int64?) {}
}

class WeakDownloadProgressDelegate {
    weak var delegate: DownloadProgressDelegate?

    init(_ delegate: DownloadProgressDelegate) {
        self.delegate = delegate
    }
}

class DownloadProgressManager {
    var downloads: [Download] = []
    private var delegates: [WeakDownloadProgressDelegate] = []

    init(downloads: [Download]) {
        combinedTotalBytesExpected = 0
        downloads.forEach({ addDownload($0) })
    }

    var combinedBytesDownloaded: Int64 = 0 {
        didSet {
            delegates.forEach({ $0.delegate?.updateCombinedBytesDownloaded(value: self.combinedBytesDownloaded) })
        }
    }

    var combinedTotalBytesExpected: Int64? {
        didSet {
            delegates.forEach({ $0.delegate?.updateCombinedTotalBytesExpected(value: self.combinedTotalBytesExpected) })
        }
    }

    func addDelegate(delegate: DownloadProgressDelegate) {
        delegates.append(WeakDownloadProgressDelegate(delegate))
    }

    func addDownload(_ download: Download) {
        self.downloads.append(download)

        if let combinedTotalBytesExpected = self.combinedTotalBytesExpected {
            if let totalBytesExpected = download.totalBytesExpected {
                self.combinedTotalBytesExpected = combinedTotalBytesExpected + totalBytesExpected
            } else {
                self.combinedTotalBytesExpected = nil
            }
        } else {
            delegates.forEach({ $0.delegate?.updateCombinedTotalBytesExpected(value: self.combinedTotalBytesExpected) })
        }
    }
}

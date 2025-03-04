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

class DownloadProgressManager {
    var downloads: [Download] = []
    var delegates: [DownloadProgressDelegate] = []

    init(downloads: [Download]) {
        combinedTotalBytesExpected = 0
        downloads.forEach({ addDownload($0) })
    }

    var combinedBytesDownloaded: Int64 = 0 {
        didSet {
            delegates.forEach({ $0.updateCombinedBytesDownloaded(value: self.combinedBytesDownloaded) })
        }
    }

    var combinedTotalBytesExpected: Int64? {
        didSet {
            delegates.forEach({ $0.updateCombinedTotalBytesExpected(value: self.combinedTotalBytesExpected) })
        }
    }

    func addDownload(_ download: Download) {
        self.downloads.append(download)

        if let combinedTotalBytesExpected = self.combinedTotalBytesExpected {
            if let totalBytesExpected = download.totalBytesExpected {
                self.combinedTotalBytesExpected = combinedTotalBytesExpected + totalBytesExpected
            } else {
                self.combinedTotalBytesExpected = nil
            }
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// A wrapper on `Logger` that facilitates tracking the documents that failed to download.
class DocumentLogger {
    let downloadExtraKey = "Pending Downloads"
    private let logger: Logger
    private var pending: [URL: Bool] = [:]

    init(logger: Logger) {
        self.logger = logger
    }

    func registerDownloadStart(url: URL) {
        guard !url.isFileURL else { return }
        pending[url] = true
    }

    func remove(url: URL) {
        pending[url] = nil
    }

    func registerDownloadFinish(url: URL) {
        // avoid logging local directories
        guard !url.isFileURL else { return }
        if pending[url] == nil {
            logger.log(
                "Document is missing but finished downloading",
                level: .info,
                category: .webview,
                extra: ["url": url.absoluteString]
            )
        }
        pending[url] = false
    }

    func logPendingDownloads() {
        let pendingDownload = pending.filter { $0.value }.count
        if pendingDownload > 0 {
            logger.log("Documents Downloads not completed",
                       level: .fatal,
                       category: .webview,
                       extra: [downloadExtraKey: "\(pendingDownload)"]
            )
        }
    }
}

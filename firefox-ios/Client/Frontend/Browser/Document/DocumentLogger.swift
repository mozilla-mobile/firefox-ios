// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// A wrapper on `Logger` that facilitates tracking the documents that failed to download.
class DocumentLogger {
    private let logger: Logger
    private var pending: [URL: Bool] = [:]

    init(logger: Logger) {
        self.logger = logger
    }

    func registerDownloadStart(url: URL) {
        pending[url] = true
    }

    func remove(url: URL) {
        pending[url] = nil
    }

    func registerDownloadFinish(url: URL) {
        if pending[url] == nil {
            // log missing download
        }
        pending[url] = false
    }

    func logPendingDownloads() {
        let pendingDownload = pending.filter { $0.value }.count
        if pendingDownload > 0 {
            logger.log("Documents Downloads not completed",
                       level: .warning,
                       category: .webview,
                       extra: ["Pending Downloads": "\(pendingDownload)"]
            )
        }
    }
}

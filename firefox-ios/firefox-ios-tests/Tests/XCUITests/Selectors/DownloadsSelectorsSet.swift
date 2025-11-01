// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol DownloadsSelectorsSet {
    var DOWNLOADS_TABLE: Selector { get }
    var all: [Selector] { get }
    func downloadedFileName(name: String) -> Selector
    func downloadedFileSize(size: String) -> Selector
}

struct DownloadsSelectors: DownloadsSelectorsSet {
    private enum IDs {
        static let downloadsTable = "DownloadsTable"
    }

    let DOWNLOADS_TABLE = Selector.tableIdOrLabel(
        IDs.downloadsTable,
        description: "Main table view for downloads list",
        groups: ["downloads"]
    )

    func downloadedFileName(name: String) -> Selector {
        Selector.staticTextByExactLabel(
            name,
            description: "Downloaded file name: \(name)",
            groups: ["downloads"]
        )
    }

    func downloadedFileSize(size: String) -> Selector {
        Selector.staticTextByExactLabel(
            size,
            description: "Downloaded file size: \(size)",
            groups: ["downloads"]
        )
    }

    var all: [Selector] { [DOWNLOADS_TABLE] }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Sentry
import Shared

protocol TabDataRetriever {
    var tabsStateArchivePath: String? { get set }
    func getTabData() -> Data?
}

struct TabDataRetrieverImplementation: TabDataRetriever {

    var tabsStateArchivePath: String?
    let fileManager: FileManager

    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }

    func getTabData() -> Data? {
        guard let tabStateArchivePath = tabsStateArchivePath else { return nil }
        fileManager.fileExists(atPath: tabStateArchivePath)
        return try? Data(contentsOf: URL(fileURLWithPath: tabStateArchivePath))
    }
}

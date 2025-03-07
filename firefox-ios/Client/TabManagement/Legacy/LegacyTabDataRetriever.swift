// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol LegacyTabDataRetriever {
    var tabsStateArchivePath: URL? { get set }
    func getTabData() -> Data?
}

struct LegacyTabDataRetrieverImplementation: LegacyTabDataRetriever {
    var tabsStateArchivePath: URL?
    let fileManager: LegacyTabFileManager

    init(fileManager: LegacyTabFileManager = FileManager.default) {
        self.fileManager = fileManager
    }

    func getTabData() -> Data? {
        guard let tabStateArchivePath = tabsStateArchivePath,
              fileManager.fileExists(atPath: tabStateArchivePath.path) else { return nil }

        return try? Data(contentsOf: tabStateArchivePath)
    }
}

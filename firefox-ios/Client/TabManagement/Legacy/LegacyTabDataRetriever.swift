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
        // Ecosia: Tabs architecture implementation from ~v112 to ~116
        self.tabsStateArchivePath = deprecatedTabsStateArchivePath()
    }

    func getTabData() -> Data? {
        guard let tabStateArchivePath = tabsStateArchivePath,
              fileManager.fileExists(atPath: tabStateArchivePath.path) else { return nil }

        return try? Data(contentsOf: tabStateArchivePath)
    }
}

// Ecosia: Tabs architecture implementation from ~v112 to ~116
// This is temprorary in order to fix a migration error, can be removed after our Ecosia 10.0.0 has been well adopted

extension LegacyTabDataRetrieverImplementation {

    private func deprecatedTabsStateArchivePath() -> URL? {
        guard let path = fileManager.tabPath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive")
    }
}

// Ecosia: End Tabs architecture implementation from ~v112 to ~116

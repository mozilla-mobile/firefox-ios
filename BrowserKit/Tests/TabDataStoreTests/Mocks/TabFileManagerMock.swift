// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import TabDataStore
import Common

class TabFileManagerMock: TabFileManager {
    func tabSessionDataDirectory() -> URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    func windowDataDirectory(isBackup: Bool) -> URL? {
        return nil
    }

    func contentsOfDirectory(at path: URL) -> [URL] {
        return []
    }

    func copyItem(at sourceURL: URL, to destinationURL: URL) throws {}

    func removeFileAt(path: URL) {}

    func removeAllFilesAt(directory: URL) {}

    func fileExists(atPath pathURL: URL) -> Bool {
        return false
    }

    func createDirectoryAtPath(path: URL) {}
}

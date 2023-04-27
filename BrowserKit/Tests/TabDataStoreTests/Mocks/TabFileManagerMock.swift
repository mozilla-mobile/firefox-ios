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
        if isBackup {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        } else {
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        }
    }

    func contentsOfDirectory(at path: URL) -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(
                    at: path,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles)
        } catch {
            return []
        }
    }

    func copyItem(at sourceURL: URL, to destinationURL: URL) throws {
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }

    func removeFileAt(path: URL) {
        try? FileManager.default.removeItem(at: path)
    }

    func removeAllFilesAt(directory: URL) {
        let fileURLs = contentsOfDirectory(at: directory)
        for fileURL in fileURLs {
            removeFileAt(path: fileURL)
        }
    }

    func fileExists(atPath pathURL: URL) -> Bool {
        return FileManager.default.fileExists(atPath: pathURL.path)
    }

    func createDirectoryAtPath(path: URL) {
        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
    }
}

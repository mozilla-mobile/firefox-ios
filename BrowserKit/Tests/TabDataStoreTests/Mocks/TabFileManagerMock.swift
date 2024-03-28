// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import TabDataStore
import Common

class TabFileManagerMock: TabFileManager {
    var primaryDirectoryURL: URL?
    var backupDirectoryURL: URL?
    var tabSessionDataDirectoryCalledCount = 0
    var windowDataDirectoryCalledCount = 0
    var pathContents: [URL]?
    var contentsOfDirectoryCalledCount = 0
    var windowData: WindowData?
    var getWindowDataFromPathCalledCount = 0
    var writeWindowDataCalledCount = 0
    var fileExistsCalledCount = 0
    var createDirectoryAtPathCalledCount = 0
    var copyItemCalledCount = 0
    var fileExists = false
    var removeFileAtCalledCount = 0
    var removeAllFilesAtCalledCount = 0
    var removeFileAtPathCalledCount = 0

    func tabSessionDataDirectory() -> URL? {
        tabSessionDataDirectoryCalledCount += 1
        return primaryDirectoryURL
    }

    func windowDataDirectory(isBackup: Bool) -> URL? {
        windowDataDirectoryCalledCount += 1
        if isBackup {
            return backupDirectoryURL
        }
        return primaryDirectoryURL
    }

    func contentsOfDirectory(at path: URL) -> [URL] {
        contentsOfDirectoryCalledCount += 1
        return pathContents ?? []
    }

    func copyItem(at sourceURL: URL, to destinationURL: URL) throws {
        copyItemCalledCount += 1
    }

    func removeAllFilesAt(directory: URL) {
        removeAllFilesAtCalledCount += 1
    }

    func removeFileAt(path: URL) {
        removeFileAtPathCalledCount += 1
    }

    func fileExists(atPath pathURL: URL) -> Bool {
        fileExistsCalledCount += 1
        return fileExists
    }

    func createDirectoryAtPath(path: URL) {
        createDirectoryAtPathCalledCount += 1
    }

    func getWindowDataFromPath(path: URL) throws -> WindowData? {
        getWindowDataFromPathCalledCount += 1
        return windowData
    }

    func writeWindowData(windowData: WindowData, to url: URL) throws {
        self.windowData = windowData
        writeWindowDataCalledCount += 1
    }
}

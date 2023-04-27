// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

public protocol TabFileManager {
    /// Determines the directory where tabs should be stored
    /// - Returns: the URL that should be used for storing tab data, can be nil
    func tabDataDirectory() -> URL?

    /// Returns the contents at a given directory
    /// - Parameter path: the location to check
    /// - Returns: a list of file URL's at the given location
    func contentsOfDirectory(at path: URL) -> [URL]
}

public struct DefaultTabFileManager: TabFileManager {
    let fileManager = FileManager.default

    public init() {}

    public func tabDataDirectory() -> URL? {
        let path: String = BrowserKitInformation.shared.sharedContainerIdentifier
        let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: path)
        return container?.appendingPathComponent("tab-data")
    }

    public func contentsOfDirectory(at path: URL) -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(
                    at: path,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles)
        } catch {
            return []
        }
    }
}

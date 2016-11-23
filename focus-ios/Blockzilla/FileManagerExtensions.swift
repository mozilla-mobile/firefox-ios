/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension FileManager {
    /// Recursively delete the file at the path, deleting its contents
    /// if it's a directory.
    func removeItemAndContents(path: String) {
        var isDirectory = ObjCBool(false)

        // Do nothing if the file doesn't exist.
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else { return }

        // If the file is a directory, first delete its contents.
        if isDirectory.boolValue {
            if let cacheFiles = try? FileManager.default.contentsOfDirectory(atPath: path) {
                for file in cacheFiles {
                    let path = (path as NSString).appendingPathComponent(file)
                    removeItemAndContents(path: path)
                }
            }
        }

        // Then delete the file itself.
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            NSLog("Unable to delete file at \(path): \(error)")
        }
    }
}

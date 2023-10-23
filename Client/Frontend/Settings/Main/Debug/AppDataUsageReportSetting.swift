// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class AppDataUsageReportSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "App Data Usage Report", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let results = generateAppDataSummary()
        UIPasteboard.general.string = results

        // Hidden debug utility not localized for now.
        showSimpleAlert("Summary generated. Text has been copied to the clipboard.")
    }

    private func showSimpleAlert(_ message: String) {
        let alert = UIAlertController(title: "App Data Usage",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        settings.present(alert, animated: true)
    }

    private func generateAppDataSummary() -> String {
        var directoriesAndSizes: [String: UInt64] = [:]
        var largeFileWarnings: [String: UInt64] = [:]
        let fileMgr = FileManager.default

        let directories: [URL] = [fileMgr.urls(for: .cachesDirectory, in: .userDomainMask).first,
                                  fileMgr.urls(for: .documentDirectory, in: .userDomainMask).first].compactMap({$0})

        for baseDirectory in directories {
            guard let enumerator = FileManager.default.enumerator(at: baseDirectory,
                                                                  includingPropertiesForKeys: [URLResourceKey.fileSizeKey],
                                                                  options: [],
                                                                  errorHandler: nil) else { continue }
            for case let fileURL as URL in enumerator {
                var isDir: ObjCBool = false
                let path = fileURL.path
                _ = fileMgr.fileExists(atPath: path, isDirectory: &isDir)
                if !isDir.boolValue {
                    let parentDir = fileURL.deletingLastPathComponent().path
                    if directoriesAndSizes[parentDir] == nil {
                        directoriesAndSizes[parentDir] = 0
                    }
                    do {
                        let values = try fileURL.resourceValues(forKeys: [URLResourceKey.fileSizeKey])
                        let size = UInt64(values.fileSize ?? 0)

                        // Log any extra-large files that should be called out in the final report
                        let warningSize = 100 * 1024 * 1024  // 100MB
                        if size >= warningSize { largeFileWarnings[path] = size }

                        // Find any directory whose path is a valid prefix for the file path
                        // This allows us to basically tally up the total sizes for parent
                        // directories along with nested child directories (if needed) all at
                        // the same time.
                        for dir in directoriesAndSizes.keys where path.hasPrefix(dir) {
                            let newSize = (directoriesAndSizes[dir] ?? 0) + size
                            directoriesAndSizes[dir] = newSize
                        }
                        // For internal debugging purposes
                        // print("File \(path) size = \((values.fileSize ?? 0) / 1024) kb")
                    } catch {
                        // Error checking cache file size
                    }
                } else {
                    // Begin tracking directory to our list
                    if directoriesAndSizes[path] == nil {
                        directoriesAndSizes[path] = 0
                    }
                }
            }
        }
        var result = "FireFox Debug Utility: App Data Summary"
        result += "\n======================================="
        result += "\n"
        for (dir, size) in directoriesAndSizes {
            result += "\nSize: \(size / 1024) kb \t\tDirectory: \t\(dir)"
        }
        result += "\n\n======================================="
        result += "\nLarge files detected: \(largeFileWarnings.count)"
        for (file, size) in largeFileWarnings {
            result += "\nSize: \(size / 1024) kb \t\tFile: \t\(file)"
        }
        return result
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class AppDataUsageReportSetting: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        // Not localized for now.
        return NSAttributedString(string: "App Data Usage Report",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let results = generateAppDataSummary()
        UIPasteboard.general.string = results.report

        // Hidden debug utility (strings not localized for now)
        showReportAlert("Summary generated. Text has been copied to the clipboard.", largeFiles: results.largeFiles)
    }

    // MARK: - Internal Utilities

    private func showReportAlert(_ message: String, largeFiles: [String: UInt64]) {
        let alert = UIAlertController(title: "App Data Usage",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.promptForLargeFileCopy(largeFiles)
        }))
        settings.present(alert, animated: true)
    }

    private func promptForLargeFileCopy(_ largeFiles: [String: UInt64]) {
        guard !largeFiles.isEmpty else { return }
        let message = "Copy large files to your Files app for debugging? This may use a significant amount of storage."
        let alert = UIAlertController(title: "Copy Large Files?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy Files", style: .default, handler: { _ in
            self.copyLargeFiles(largeFiles)
        }))
        alert.addAction(UIAlertAction(title: "Don't Copy", style: .cancel))
        settings.present(alert, animated: true)
    }

    private func copyLargeFiles(_ largeFiles: [String: UInt64]) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        for file in largeFiles.keys {
            let filePath = file as String
            let sourceURL = URL(fileURLWithPath: filePath)
            let destinationURL = documentsURL.appendingPathComponent(sourceURL.lastPathComponent)
            guard !fileManager.fileExists(atPath: destinationURL.path) else { continue }
            try? fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }

    private func generateAppDataSummary() -> (report: String, largeFiles: [String: UInt64]) {
        var directoriesAndSizes: [String: UInt64] = [:]
        var largeFileWarnings: [String: UInt64] = [:]
        let fileManager = FileManager.default
        let warningSize = 100 * 1024 * 1024  // (100MB) File size threshold to log for report

        let searchDirectories: [FileManager.SearchPathDirectory] =
        [.cachesDirectory, .documentDirectory, .applicationSupportDirectory, .downloadsDirectory]
        var directoryURLs: [URL] = searchDirectories
            .compactMap({ fileManager.urls(for: $0, in: .userDomainMask).first })

        // Also calculate usage of database and other Profile data in shared container
        let containerID = AppInfo.sharedContainerIdentifier
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: containerID) {
            directoryURLs.append(containerURL)
        }

        for baseDirectory in directoryURLs {
            guard let enumerator = fileManager.enumerator(at: baseDirectory,
                                                          includingPropertiesForKeys: [URLResourceKey.fileSizeKey],
                                                          options: [],
                                                          errorHandler: nil) else { continue }
            for case let fileURL as URL in enumerator {
                var isDir: ObjCBool = false
                let path = fileURL.path
                if fileManager.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue {
                    let parentDir = fileURL.deletingLastPathComponent().path
                    if directoriesAndSizes[parentDir] == nil { directoriesAndSizes[parentDir] = 0 }
                    do {
                        let values = try fileURL.resourceValues(forKeys: [URLResourceKey.fileSizeKey])
                        let size = UInt64(values.fileSize ?? 0)

                        if size >= warningSize { largeFileWarnings[path] = size }

                        // Find any directory whose path is a valid prefix for the file path
                        // This allows us to tally the total sizes for parent directories
                        // along with nested children (if needed) at the same time.
                        for dir in directoriesAndSizes.keys where path.hasPrefix(dir) {
                            let newSize = (directoriesAndSizes[dir] ?? 0) + size
                            directoriesAndSizes[dir] = newSize
                        }
                    } catch {
                        print("Error checking file size: \(error)")
                    }
                } else {
                    if directoriesAndSizes[path] == nil { directoriesAndSizes[path] = 0 }
                }
            }
        }

        // Attempt to calculate total space taken by UserDefaults plist
        var userDefaultsSize: UInt64 = 0
        let plistComponent = "/Preferences/\(Bundle.main.bundleIdentifier ?? "").plist"
        if let prefsURL = fileManager
            .urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(plistComponent) {
            if let values = try? prefsURL.resourceValues(forKeys: [URLResourceKey.fileSizeKey]) {
                userDefaultsSize = UInt64(values.fileSize ?? 0)
            }
        }

        let directoriesAndSizesSorted = directoriesAndSizes
            .map({ return ($0, $1) })
            .sorted(by: { return $0.1 > $1.1 })

        var result = "FireFox Debug Utility: App Data Summary"
        result += "\n======================================="
        result += "\n"
        for (dir, size) in directoriesAndSizesSorted {
            result += "\nSize: \(size / 1024) kb \t\tDirectory: \t\(dir)"
        }
        result += "\n\n======================================="
        result += "\nUser defaults: \(userDefaultsSize / 1024) kb"
        result += "\n\n======================================="
        result += "\nLarge files detected: \(largeFileWarnings.count)"
        for (file, size) in largeFileWarnings {
            result += "\nSize: \(size / 1024) kb \t\tFile: \t\(file)"
        }
        return (result, largeFileWarnings)
    }
}

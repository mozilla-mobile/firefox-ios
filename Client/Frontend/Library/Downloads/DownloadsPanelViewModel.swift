// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class DownloadsPanelViewModel {
    var groupedDownloadedFiles = DateGroupedTableData<DownloadedFile>()
    var fileExtensionIcons: [String: UIImage] = [:]

    func reloadData() {
        groupedDownloadedFiles = DateGroupedTableData<DownloadedFile>()

        let downloadedFiles = fetchData()
        for downloadedFile in downloadedFiles {
            groupedDownloadedFiles.add(downloadedFile, timestamp: downloadedFile.lastModified.timeIntervalSince1970)
        }

        fileExtensionIcons = [:]
    }

    func fetchData() -> [DownloadedFile] {
        var downloadedFiles: [DownloadedFile] = []
        do {
            let downloadsPath = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false).appendingPathComponent("Downloads")
            let files = try FileManager.default.contentsOfDirectory(
                at: downloadsPath,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles,
                          .skipsPackageDescendants,
                          .skipsSubdirectoryDescendants])

            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path) as NSDictionary
                let downloadedFile = DownloadedFile(path: file, size: attributes.fileSize(), lastModified: attributes.fileModificationDate() ?? Date())
                downloadedFiles.append(downloadedFile)
            }
        } catch let error {
            print("Unable to get files in Downloads folder: \(error.localizedDescription)")
            return []
        }

        return downloadedFiles.sorted(by: { first, second -> Bool in
            return first.lastModified > second.lastModified
        })
    }

    func downloadedFileForIndexPath(_ indexPath: IndexPath) -> DownloadedFile? {
        let downloadedFilesInSection = groupedDownloadedFiles.itemsForSection(indexPath.section)
        return downloadedFilesInSection[safe: indexPath.row]
    }

    func isFirstSection(_ section: Int) -> Bool {
        for index in 0..<section {
            if hasDownloadItem(for: index) {
                return false
            }
        }
        return true
    }

    func headerTitle(for section: Int) -> String? {
        switch section {
        case 0:
           return .LibraryPanel.Sections.Today
        case 1:
            return .LibraryPanel.Sections.Yesterday
        case 2:
            return .LibraryPanel.Sections.LastWeek
        case 3:
            return .LibraryPanel.Sections.LastMonth
        default:
            return nil
        }
    }

    func hasDownloadItem(for section: Int) -> Bool {
        return groupedDownloadedFiles.numberOfItemsForSection(section) > 0
    }
}

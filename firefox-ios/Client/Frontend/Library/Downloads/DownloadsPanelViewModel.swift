// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class DownloadsPanelViewModel {
    private var groupedDownloadedFiles = DateGroupedTableData<DownloadedFile>()
    var fileExtensionIcons: [String: UIImage] = [:]
    var fileFetcher: DownloadFileFetcher

    var hasDownloadedFiles: Bool {
        return !groupedDownloadedFiles.isEmpty
    }

    init(fileFetcher: DownloadFileFetcher = DefaultDownloadFileFetcher()) {
        self.fileFetcher = fileFetcher
    }

    func reloadData() {
        groupedDownloadedFiles = DateGroupedTableData<DownloadedFile>()

        let downloadedFiles = fileFetcher.fetchData()
        for downloadedFile in downloadedFiles {
            groupedDownloadedFiles.add(downloadedFile, timestamp: downloadedFile.lastModified.timeIntervalSince1970)
        }

        fileExtensionIcons = [:]
    }

    func downloadedFileForIndexPath(_ indexPath: IndexPath) -> DownloadedFile? {
        let downloadedFilesInSection = groupedDownloadedFiles.itemsForSection(indexPath.section)
        return downloadedFilesInSection[safe: indexPath.row]
    }

    func isFirstSection(_ section: Int) -> Bool {
        for index in 0..<section where hasDownloadedItem(for: index) {
            return false
        }
        return true
    }

    func headerTitle(for section: Int) -> String? {
        switch section {
        case 0:
            return .LibraryPanel.Sections.LastTwentyFourHours
        case 1:
            return .LibraryPanel.Sections.LastSevenDays
        case 2:
            return .LibraryPanel.Sections.LastFourWeeks
        default:
            return nil
        }
    }

    func hasDownloadedItem(for section: Int) -> Bool {
        return groupedDownloadedFiles.numberOfItemsForSection(section) > 0
    }

    func getNumberOfItems(for section: Int) -> Int {
        return groupedDownloadedFiles.numberOfItemsForSection(section)
    }

    func removeDownloadedFile(_ downloadedFile: DownloadedFile) {
        groupedDownloadedFiles.remove(downloadedFile)
    }
}

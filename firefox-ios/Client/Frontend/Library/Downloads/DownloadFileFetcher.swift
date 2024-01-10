// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol DownloadFileFetcher {
    func fetchData() -> [DownloadedFile]
}

class DefaultDownloadFileFetcher: DownloadFileFetcher {
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
                let downloadedFile = DownloadedFile(
                    path: file,
                    size: attributes.fileSize(),
                    lastModified: attributes.fileModificationDate() ?? Date()
                )
                downloadedFiles.append(downloadedFile)
            }
        } catch {
            return []
        }

        return downloadedFiles.sorted(by: { first, second -> Bool in
            return first.lastModified > second.lastModified
        })
    }
}

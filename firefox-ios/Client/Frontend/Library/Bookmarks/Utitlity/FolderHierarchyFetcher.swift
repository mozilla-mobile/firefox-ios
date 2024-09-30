// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

protocol FolderHierarchyFetcher {
    func fetchFolders() async -> [(folder: BookmarkFolderData, indent: Int)]
}

struct DefaultFolderHierarchyFetcher: FolderHierarchyFetcher {
    let profile: Profile
    let rootFolderGUID: String

    func fetchFolders() async -> [(folder: BookmarkFolderData, indent: Int)] {
        return await withCheckedContinuation { continuation in
            profile.places.getBookmarksTree(rootGUID: rootFolderGUID,
                                            recursive: true).uponQueue(.main) {  data in
                var folders = [(folder: BookmarkFolderData, indent: Int)]()
                defer {
                    continuation.resume(returning: folders)
                }
                guard let rootFolder = data.successValue as? BookmarkFolderData else { return }
                let childrenFolders = rootFolder.children?.compactMap {
                    return $0 as? BookmarkFolderData
                }
                for folder in childrenFolders ?? [] {
                    recursiveAddSubFolders(folder, folders: &folders)
                }
            }
        }
    }

    private func recursiveAddSubFolders(_ folder: BookmarkFolderData,
                                        folders: inout [(folder: BookmarkFolderData, indent: Int)],
                                        indent: Int = 0) {
        folders.append((folder: folder, indent: indent))
        for case let subFolder as BookmarkFolderData in folder.children ?? [] {
            let indentation = subFolder.isRoot ? 0 : indent + 1
            recursiveAddSubFolders(subFolder, folders: &folders, indent: indentation)
        }
    }
}

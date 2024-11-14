// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

protocol FolderHierarchyFetcher {
    func fetchFolders() async -> [Folder]
}

struct Folder: Equatable {
    init(title: String, guid: String, indentation: Int) {
        self.title = Self.localizedTitle(guid) ?? title
        self.guid = guid
        self.indentation = indentation
    }

    let title: String
    let guid: String
    let indentation: Int

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.guid == rhs.guid
    }

    static func localizedTitle(_ guid: String) -> String? {
        return LocalizedRootBookmarkFolderStrings[guid]
    }
}

struct DefaultFolderHierarchyFetcher: FolderHierarchyFetcher, BookmarksRefactorFeatureFlagProvider {
    let profile: Profile
    let rootFolderGUID: String

    func fetchFolders() async -> [Folder] {
        let numDesktopBookmarks = await countDesktopBookmarks()
        return await withCheckedContinuation { continuation in
            profile.places.getBookmarksTree(rootGUID: rootFolderGUID,
                                            recursive: true).uponQueue(.main) { data in
                var folders = [Folder]()
                defer {
                    continuation.resume(returning: folders)
                }
                guard let rootFolder = data.successValue as? BookmarkFolderData else { return }
                let hasDesktopBookmarks = (numDesktopBookmarks ?? 0) > 0

                let childrenFolders = rootFolder.children?.compactMap {
                    return $0 as? BookmarkFolderData
                }

                for folder in childrenFolders ?? [] {
                    recursiveAddSubFolders(folder, folders: &folders, hasDesktopBookmarks: hasDesktopBookmarks)
                }
            }
        }
    }

    private func recursiveAddSubFolders(_ folder: BookmarkFolderData,
                                        folders: inout [Folder],
                                        hasDesktopBookmarks: Bool,
                                        indent: Int = 0) {
        if !BookmarkRoots.DesktopRoots.contains(folder.guid) || hasDesktopBookmarks || !isBookmarkRefactorEnabled {
            folders.append(Folder(title: folder.title, guid: folder.guid, indentation: indent))
        } else { return }
        for case let subFolder as BookmarkFolderData in folder.children ?? [] {
            let indentation = subFolder.isRoot ? 0 : indent + 1
            recursiveAddSubFolders(
                subFolder,
                folders: &folders,
                hasDesktopBookmarks: hasDesktopBookmarks,
                indent: indentation
            )
        }
    }

    private func countDesktopBookmarks() async -> Int? {
        return await withCheckedContinuation { continuation in
            profile.places.countBookmarksInTrees(folderGuids: BookmarkRoots.DesktopRoots.map { $0 }) { result in
                switch result {
                case .success(let count):
                    continuation.resume(returning: count)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

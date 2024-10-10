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

struct DefaultFolderHierarchyFetcher: FolderHierarchyFetcher {
    let profile: Profile
    let rootFolderGUID: String

    func fetchFolders() async -> [Folder] {
        return await withCheckedContinuation { continuation in
            profile.places.getBookmarksTree(rootGUID: rootFolderGUID,
                                            recursive: true).uponQueue(.main) {  data in
                var folders = [Folder]()
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
                                        folders: inout [Folder],
                                        indent: Int = 0) {
        folders.append(Folder(title: folder.title, guid: folder.guid, indentation: indent))
        for case let subFolder as BookmarkFolderData in folder.children ?? [] {
            let indentation = subFolder.isRoot ? 0 : indent + 1
            recursiveAddSubFolders(subFolder, folders: &folders, indent: indentation)
        }
    }
}

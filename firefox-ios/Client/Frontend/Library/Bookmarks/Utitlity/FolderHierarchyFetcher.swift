// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

protocol FolderHierarchyFetcher {
    func fetchFolders(excludedGuids: [String]) async -> [Folder]
    func fetchFolders() async -> [Folder]
}

extension FolderHierarchyFetcher {
    func fetchFolders() async -> [Folder] {
        await fetchFolders(excludedGuids: [])
    }
}

struct Folder: Equatable, Hashable {
    init(title: String, guid: String, indentation: Int) {
        self.title = Self.localizedTitle(guid) ?? title
        self.guid = guid
        self.indentation = indentation
    }

    let title: String
    let guid: String
    let indentation: Int

    static let DesktopFolderHeaderPlaceholderGuid = "DUMMY"

    static func localizedTitle(_ guid: String) -> String? {
        return LocalizedRootBookmarkFolderStrings[guid]
    }
}

struct DefaultFolderHierarchyFetcher: FolderHierarchyFetcher, BookmarksRefactorFeatureFlagProvider {
    let profile: Profile
    let rootFolderGUID: String

    func fetchFolders(excludedGuids: [String] = []) async -> [Folder] {
        let numDesktopBookmarks = await countDesktopBookmarks()
        return await withCheckedContinuation { continuation in
            profile.places.getBookmarksTree(rootGUID: rootFolderGUID, recursive: true) { result in
                var folders = [Folder]()
                defer { continuation.resume(returning: folders) }
                switch result {
                case .success(let data):
                    guard let rootFolder = data as? BookmarkFolderData else { return }
                    let hasDesktopBookmarks = (numDesktopBookmarks ?? 0) > 0

                    var childrenFolders = rootFolder.children?.compactMap {
                        return $0 as? BookmarkFolderData
                    }

                    // Since desktop folders always exist in the backend, we should only display them if at least one of
                    // them contains a bookmark
                    var desktopFolders: [BookmarkFolderData] = []
                    if hasDesktopBookmarks {
                        desktopFolders = childrenFolders?.filter {
                            BookmarkRoots.DesktopRoots.contains($0.guid)
                        } ?? []

                        // Remove desktop folders from the root folder hierarchy so they aren't added when recursing
                        // the root folder
                        childrenFolders?.removeAll {
                            BookmarkRoots.DesktopRoots.contains($0.guid)
                        }
                    }

                    for folder in childrenFolders ?? [] {
                        recursiveAddSubFolders(folder,
                                               folders: &folders,
                                               hasDesktopBookmarks: hasDesktopBookmarks,
                                               excludedGuids: excludedGuids,
                                               prefixFolders: desktopFolders)
                    }
                case .failure: return
                }
            }
        }
    }

    /// Recursively adds folder objects to the inout "folders" parameter
    /// - Parameters:
    ///   - folder: folder to recurse
    ///   - folders: Array containing all appended folders
    ///   - hasDesktopBookmarks: Whether or not the folder contains desktop bookmarks in its subfolder hierarchy
    ///   - indent: Folder indentation
    ///   - prefixFolders: Optional folders to be prepended to the top of the "folder" subfolder hierarchy.
    ///                    Namely used to prepend the desktop folders to the top of the mobile bookmarks subfolder hierarchy
    private func recursiveAddSubFolders(_ folder: BookmarkFolderData,
                                        folders: inout [Folder],
                                        hasDesktopBookmarks: Bool,
                                        indent: Int = 0,
                                        excludedGuids: [String],
                                        prefixFolders: [BookmarkFolderData] = []) {
        // Only add the folder if it is:
        // a) A desktop folder and we have desktop bookmarks
        // b) Not a desktop or excluded folder
        if (BookmarkRoots.DesktopRoots.contains(folder.guid) && hasDesktopBookmarks) ||
            (!BookmarkRoots.DesktopRoots.contains(folder.guid) && !excludedGuids.contains(folder.guid)) {
            folders.append(Folder(title: folder.title, guid: folder.guid, indentation: indent))

            // Prepend desktop folders to the top of the mobile bookmarks folder hierarchy
            if folder.guid == BookmarkRoots.MobileFolderGUID {
                prependDesktopFolders(folder, folders: &folders, indent: indent, prefixFolders: prefixFolders)
            }
        } else { return }
        for case let subFolder as BookmarkFolderData in folder.children ?? [] {
            let indentation = subFolder.isRoot ? 0 : indent + 1
            recursiveAddSubFolders(
                subFolder,
                folders: &folders,
                hasDesktopBookmarks: hasDesktopBookmarks,
                indent: indentation,
                excludedGuids: excludedGuids
            )
        }
    }

    private func countDesktopBookmarks() async -> Int? {
        return await withUnsafeContinuation { continuation in
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

    private func prependDesktopFolders(_ folder: BookmarkFolderData,
                                       folders: inout [Folder],
                                       indent: Int = 0,
                                       prefixFolders: [BookmarkFolderData] = []) {
        prefixFolders.forEach {
            folders.append(Folder(title: $0.title, guid: $0.guid, indentation: indent + 2))
        }
        // Find the first desktop folder and prepend a dummy folder object to use for the "DESKTOP BOOKMARKS" header
        if let firstDesktopFolderIndex = folders.firstIndex(where: { BookmarkRoots.DesktopRoots.contains($0.guid) }) {
            let dummyFolder = Folder(title: "", guid: Folder.DesktopFolderHeaderPlaceholderGuid, indentation: indent + 2)
            folders.insert(dummyFolder, at: firstDesktopFolderIndex)
        }
    }
}

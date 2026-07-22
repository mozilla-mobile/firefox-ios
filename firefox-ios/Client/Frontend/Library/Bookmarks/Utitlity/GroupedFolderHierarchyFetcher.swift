// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

protocol GroupedFolderHierarchyFetcher {
    func fetchFolders(excludedGuids: [String]) async -> [GroupedFolder]
    func fetchFolders() async -> [GroupedFolder]
}

extension GroupedFolderHierarchyFetcher {
    func fetchFolders() async -> [GroupedFolder] {
        await fetchFolders(excludedGuids: [])
    }
}

struct GroupedFolder: Equatable, Hashable {
    init(title: String, guid: String, indentation: Int, parentTitle: String? = nil, isDesktopRoot: Bool = false) {
        self.title = Self.localizedTitle(guid) ?? title
        self.guid = guid
        self.indentation = indentation
        self.parentTitle = parentTitle
        self.isDesktopRoot = isDesktopRoot
    }

    let title: String
    let guid: String
    let indentation: Int
    let parentTitle: String?
    let isDesktopRoot: Bool

    static func localizedTitle(_ guid: String) -> String? {
        return LocalizedRootBookmarkFolderStrings[guid]
    }
}

struct FolderGroup: Equatable, Identifiable {
    let id: String
    let title: String
    var folders: [GroupedFolder]
    var isExpanded: Bool

    static let mobileGroupID = "group.mobile"
    static let desktopGroupID = "group.desktop"

    struct Block: Equatable {
        let folders: [GroupedFolder]
    }

    var blocks: [Block] {
        var result: [Block] = []
        var current: [GroupedFolder] = []
        for folder in folders {
            if folder.indentation == 0, !current.isEmpty {
                result.append(Block(folders: current))
                current = []
            }
            current.append(folder)
        }
        if !current.isEmpty {
            result.append(Block(folders: current))
        }
        return result
    }

    static func makeGroups(from folders: [GroupedFolder],
                           mobileTitle: String,
                           desktopTitle: String,
                           mobileExpandedByDefault: Bool,
                           desktopExpandedByDefault: Bool) -> [FolderGroup] {
        let mobileFolders = folders.filter { !$0.isDesktopRoot }
        let desktopFolders = folders.filter { $0.isDesktopRoot }

        guard !desktopFolders.isEmpty else {
            return [FolderGroup(id: mobileGroupID,
                                title: mobileTitle,
                                folders: mobileFolders,
                                isExpanded: mobileExpandedByDefault)]
        }

        return [
            FolderGroup(id: mobileGroupID,
                        title: mobileTitle,
                        folders: mobileFolders,
                        isExpanded: mobileExpandedByDefault),
            FolderGroup(id: desktopGroupID,
                        title: desktopTitle,
                        folders: desktopFolders,
                        isExpanded: desktopExpandedByDefault)
        ]
    }
}

struct GroupedDefaultFolderHierarchyFetcher: GroupedFolderHierarchyFetcher {
    let profile: Profile
    let rootFolderGUID: String

    func fetchFolders(excludedGuids: [String] = []) async -> [GroupedFolder] {
        let numDesktopBookmarks = await countDesktopBookmarks()
        return await withCheckedContinuation { continuation in
            profile.places.getBookmarksTree(rootGUID: rootFolderGUID, recursive: true) { result in
                var folders = [GroupedFolder]()
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
    ///   - isDesktopSubtree: True if this folder is the Desktop subtree's root or a descendant of it -
    ///                    propagated to children so every folder in the subtree (not just the root)
    ///                    can be identified later via `GroupedFolder.isDesktopRoot`.
    private func recursiveAddSubFolders(_ folder: BookmarkFolderData,
                                        folders: inout [GroupedFolder],
                                        hasDesktopBookmarks: Bool,
                                        indent: Int = 0,
                                        excludedGuids: [String],
                                        prefixFolders: [BookmarkFolderData] = [],
                                        parentTitle: String? = nil,
                                        isDesktopSubtree: Bool = false) {
        let isDesktopRootFolder = BookmarkRoots.DesktopRoots.contains(folder.guid)
        let isDesktop = isDesktopRootFolder || isDesktopSubtree

        // Only add the folder if it is:
        // a) A desktop folder and we have desktop bookmarks
        // b) Not a desktop or excluded folder
        if (isDesktopRootFolder && hasDesktopBookmarks) ||
            (!isDesktopRootFolder && !excludedGuids.contains(folder.guid)) {
            folders.append(GroupedFolder(title: folder.title,
                                         guid: folder.guid,
                                         indentation: indent,
                                         parentTitle: indent == 0 ? nil : parentTitle,
                                         isDesktopRoot: isDesktop))

            // Prepend desktop folders to the top of the mobile bookmarks folder hierarchy
            if folder.guid == BookmarkRoots.MobileFolderGUID {
                prependDesktopFolders(
                    folder,
                    folders: &folders,
                    excludedGuids: excludedGuids,
                    prefixFolders: prefixFolders
                )
            }
        } else { return }
        for case let subFolder as BookmarkFolderData in folder.children ?? [] {
            let indentation = folder.guid == BookmarkRoots.MobileFolderGUID ? 0 : 1
            recursiveAddSubFolders(
                subFolder,
                folders: &folders,
                hasDesktopBookmarks: hasDesktopBookmarks,
                indent: indentation,
                excludedGuids: excludedGuids,
                parentTitle: GroupedFolder.localizedTitle(folder.guid) ?? folder.title,
                isDesktopSubtree: isDesktop
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

    private func prependDesktopFolders(_ folder: BookmarkFolderData,
                                       folders: inout [GroupedFolder],
                                       excludedGuids: [String],
                                       prefixFolders: [BookmarkFolderData] = []) {
        prefixFolders.forEach {
            recursiveAddSubFolders(
                $0,
                folders: &folders,
                hasDesktopBookmarks: true,
                excludedGuids: excludedGuids,
                isDesktopSubtree: true
            )
        }
    }
}

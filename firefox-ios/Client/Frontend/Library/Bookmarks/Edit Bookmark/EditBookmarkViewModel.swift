// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

class EditBookmarkViewModel {
    init(parentFolder: FxBookmarkNode,
         node: FxBookmarkNode?,
         profile: Profile,
         bookmarksSaver: BookmarksSaver? = nil,
         folderFetcher: FolderHierarchyFetcher? = nil) {
        self.parentFolder = parentFolder
        self.node = node as? BookmarkItemData
        self.profile = profile
        self.bookmarksSaver = bookmarksSaver ?? DefaultBookmarksSaver(profile: profile)
        self.folderFetcher = folderFetcher ?? DefaultFolderHierarchyFetcher(profile: profile,
                                                                            rootFolderGUID: BookmarkRoots.RootGUID)
        guard let parentFolder = parentFolder as? BookmarkFolderData else { return }
        folderStructures.append(Folder(title: title(for: parentFolder),
                                       guid: parentFolder.guid,
                                       indentation: 0,
                                       isSelected: true))
    }

    struct Folder {
        let title: String
        let guid: String
        let indentation: Int
        var isSelected: Bool
    }
    typealias VoidReturnCallback = () -> Void

    private let parentFolder: FxBookmarkNode
    private var node: BookmarkItemData?
    private let profile: Profile
    private let folderFetcher: FolderHierarchyFetcher
    private let bookmarksSaver: BookmarksSaver
    
    private var isFolderCollapsed = true
    private(set) var folderStructures: [Folder] = []
    
    var bookmarkTitle: String {
        return node?.title ?? ""
    }
    var bookmarkURL: String {
        return node?.url ?? ""
    }
    
    var onFolderStatusUpdate: VoidReturnCallback?
    var onBookmarkSaved: VoidReturnCallback?

    func backNavigationButtonTitle() -> String {
        if parentFolder.guid == BookmarkRoots.MobileFolderGUID {
            // TODO: - translate
            return "All"
        }
        return parentFolder.title
    }

    func shouldShowDisclosureIndicator(isFolderSelected: Bool) -> Bool {
        return isFolderSelected && !isFolderCollapsed
    }

    func selectFolder(_ folder: Folder) {
        isFolderCollapsed.toggle()
        if isFolderCollapsed {
            var selectedFolder = folder
            selectedFolder.isSelected = true
            folderStructures = [selectedFolder]
            onFolderStatusUpdate?()
        } else {
            getFolderStructure(folder)
        }
    }

    private func getFolderStructure(_ selectedFolder: Folder) {
        Task { @MainActor [weak self] in
            let folders = (await self?.folderFetcher.fetchFolders())?.map { data in
                return Folder(title: self?.title(for: data.folder) ?? "",
                              guid: data.folder.guid,
                              indentation: data.indent,
                              isSelected: selectedFolder.guid == data.folder.guid)
            }
            guard let folders else { return }
            self?.folderStructures = folders
            self?.onFolderStatusUpdate?()
        }
    }

    private func title(for folder: BookmarkFolderData) -> String {
        return LocalizedRootBookmarkFolderStrings[folder.guid] ?? folder.title
    }

    func setUpdatedTitle(_ title: String) {
        node = node?.copy(with: title, url: bookmarkURL)
    }

    func setUpdatedURL(_ url: String) {
        node = node?.copy(with: bookmarkTitle, url: url)
    }

    func saveBookmark() {
        let selectedFolder = folderStructures.first {
            return $0.isSelected
        }
        guard let selectedFolder, let node else { return }
        Task { @MainActor [weak self] in
            _ = await self?.bookmarksSaver.save(bookmark: node,
                                                parentFolderGUID: selectedFolder.guid)
            self?.onBookmarkSaved?()
        }
    }
}

extension BookmarkItemData {
    func copy(with title: String, url: String) -> BookmarkItemData {
        return BookmarkItemData(guid: guid,
                                dateAdded: dateAdded,
                                lastModified: lastModified,
                                parentGUID: parentGUID,
                                position: position,
                                url: url,
                                title: title)
    }
}

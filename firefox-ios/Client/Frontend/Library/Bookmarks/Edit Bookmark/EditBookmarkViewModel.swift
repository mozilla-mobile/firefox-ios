// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Shared

typealias VoidReturnCallback = () -> Void

class EditBookmarkViewModel {
    private let parentFolder: FxBookmarkNode
    private var node: BookmarkItemData?
    private let profile: Profile
    private let folderFetcher: FolderHierarchyFetcher
    private let bookmarksSaver: BookmarksSaver

    private var isFolderCollapsed = true
    private(set) var folderStructures: [Folder] = []
    private(set) var selectedFolder: Folder?

    var bookmarkTitle: String {
        return node?.title ?? ""
    }
    var bookmarkURL: String {
        return node?.url ?? ""
    }

    var onFolderStatusUpdate: VoidReturnCallback?
    var onBookmarkSaved: VoidReturnCallback?

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
        let folder = Folder(title: parentFolder.title, guid: parentFolder.guid, indentation: 0)
        folderStructures = [folder]
        selectedFolder = folder
    }

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
            selectedFolder = folder
            folderStructures = [folder]
            onFolderStatusUpdate?()
        } else {
            getFolderStructure(folder)
        }
    }

    private func getFolderStructure(_ selectedFolder: Folder) {
        Task { @MainActor [weak self] in
            let folders = await self?.folderFetcher.fetchFolders()
            guard let folders else { return }
            self?.folderStructures = folders
            self?.selectedFolder = selectedFolder
            self?.onFolderStatusUpdate?()
        }
    }

    func setUpdatedTitle(_ title: String) {
        node = node?.copy(with: title, url: bookmarkURL)
    }

    func setUpdatedURL(_ url: String) {
        node = node?.copy(with: bookmarkTitle, url: url)
    }

    func saveBookmark() {
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

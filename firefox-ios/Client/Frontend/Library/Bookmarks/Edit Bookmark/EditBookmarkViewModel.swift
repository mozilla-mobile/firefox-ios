// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

typealias VoidReturnCallback = () -> Void

protocol ParentFolderSelector: AnyObject {
    /// In some cases, a child `EditFolderViewController` needs to pass information to a parent `EditBookmarkViewController`
    /// to select the folder that was just created
    /// - Parameter folder: The folder that was created in the `EditFolderViewController`
    func selectFolderCreatedFromChild(folder: Folder)
}

class EditBookmarkViewModel: ParentFolderSelector {
    private let parentFolder: FxBookmarkNode
    private var node: BookmarkItemData?
    private let profile: Profile
    private let logger: Logger
    private let folderFetcher: FolderHierarchyFetcher
    private let bookmarksSaver: BookmarksSaver
    weak var bookmarkCoordinatorDelegate: BookmarksCoordinatorDelegate?

    private(set) var isFolderCollapsed = true
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

    var getBackNavigationButtonTitle: String {
        if parentFolder.guid == BookmarkRoots.MobileFolderGUID {
            return .Bookmarks.Menu.AllBookmarks
        }
        return parentFolder.title
    }

    init(parentFolder: FxBookmarkNode,
         node: FxBookmarkNode?,
         profile: Profile,
         logger: Logger = DefaultLogger.shared,
         bookmarksSaver: BookmarksSaver? = nil,
         folderFetcher: FolderHierarchyFetcher? = nil) {
        self.parentFolder = parentFolder
        self.node = node as? BookmarkItemData
        self.profile = profile
        self.logger = logger
        self.bookmarksSaver = bookmarksSaver ?? DefaultBookmarksSaver(profile: profile)
        self.folderFetcher = folderFetcher ?? DefaultFolderHierarchyFetcher(profile: profile,
                                                                            rootFolderGUID: BookmarkRoots.RootGUID)
        let folder = Folder(title: parentFolder.title, guid: parentFolder.guid, indentation: 0)
        folderStructures = [folder]
        selectedFolder = folder
    }

    func shouldShowDisclosureIndicatorForFolder(_ folder: Folder) -> Bool {
        let shouldShowDisclosureIndicator = folder.guid == selectedFolder?.guid
        return shouldShowDisclosureIndicator && !isFolderCollapsed
    }

    func indentationForFolder(_ folder: Folder) -> Int {
        if isFolderCollapsed {
            return 0
        }
        return folder.indentation
    }

    func selectFolder(_ folder: Folder) {
        isFolderCollapsed.toggle()
        selectedFolder = folder
        if isFolderCollapsed {
            folderStructures = [folder]
            onFolderStatusUpdate?()
        } else {
            getFolderStructure(folder)
        }
    }

    func createNewFolder() {
        bookmarkCoordinatorDelegate?.showBookmarkDetail(
            bookmarkType: .folder,
            parentBookmarkFolder: parentFolder,
            parentFolderSelector: self)
    }

    private func getFolderStructure(_ selectedFolder: Folder) {
        Task { @MainActor [weak self] in
            let folders = await self?.folderFetcher.fetchFolders()
            guard let folders else { return }
            self?.folderStructures = folders
            self?.onFolderStatusUpdate?()
        }
    }

    func setUpdatedTitle(_ title: String) {
        node = node?.copy(with: title, url: bookmarkURL)
    }

    func setUpdatedURL(_ url: String) {
        node = node?.copy(with: bookmarkTitle, url: url)
    }

    @discardableResult
    func saveBookmark() -> Task<Void, Never>? {
        guard let selectedFolder, let node else { return nil }
        return Task { @MainActor [weak self] in
            // There is no way to access the EditBookmarkViewController without the bookmark already existing,
            // so this call will always try to update an existing bookmark
            let result = await self?.bookmarksSaver.save(bookmark: node,
                                                         parentFolderGUID: selectedFolder.guid)
            // Only update the recent folder pref if it doesn't match whats saved in the pref
            if selectedFolder.guid != self?.profile.prefs.stringForKey(PrefsKeys.RecentBookmarkFolder) {
                switch result {
                case .success:
                    self?.profile.prefs.setString(selectedFolder.guid, forKey: PrefsKeys.RecentBookmarkFolder)
                case .failure(let error):
                    self?.logger.log("Failed to save bookmark: \(error)", level: .warning, category: .library)
                case .none:
                    break
                }
            }

            self?.onBookmarkSaved?()
        }
    }

    func didFinish() {
        bookmarkCoordinatorDelegate?.didFinish()
    }

    // MARK: ParentFolderSelector

    func selectFolderCreatedFromChild(folder: Folder) {
        isFolderCollapsed = true
        selectedFolder = folder
        folderStructures = [folder]
        onFolderStatusUpdate?()
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

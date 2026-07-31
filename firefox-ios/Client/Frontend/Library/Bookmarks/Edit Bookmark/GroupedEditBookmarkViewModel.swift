// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

protocol GroupedParentFolderSelector: AnyObject {
    /// In some cases, a child `GroupedEditFolderViewController` needs to pass information
    /// to a parent `GroupedEditBookmarkViewController` to select the folder that was just created
    /// - Parameter folder: The folder that was created in the `GroupedEditFolderViewController`
    @MainActor
    func selectFolderCreatedFromChild(folder: GroupedFolder)
}

// FIXME: FXIOS-16473 Make GroupedEditBookmarkViewModel actually Sendable
class GroupedEditBookmarkViewModel: GroupedParentFolderSelector, @unchecked Sendable {
    static let mobileHeaderPlaceholderGuid = "EditBookmarkViewModel.mobileHeaderPlaceholder"
    static let desktopHeaderPlaceholderGuid = "EditBookmarkViewModel.desktopHeaderPlaceholder"

    private static let placeholderIndentation = 0

    private let parentFolder: FxBookmarkNode
    private var node: BookmarkItemData?
    private let profile: Profile
    private let logger: Logger
    private let folderFetcher: GroupedFolderHierarchyFetcher
    private let bookmarksSaver: BookmarksSaver
    weak var bookmarkCoordinatorDelegate: BookmarksCoordinatorDelegate?

    private(set) var isFolderCollapsed = true
    private(set) var folderStructures: [GroupedFolder] = []
    private(set) var selectedFolder: GroupedFolder?

    var bookmarkTitle: String {
        return node?.title ?? ""
    }
    var bookmarkURL: String {
        return node?.url ?? ""
    }

    var onFolderStatusUpdate: (@MainActor () -> Void)?
    var onBookmarkSaved: (@MainActor () -> Void)?

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
         folderFetcher: GroupedFolderHierarchyFetcher? = nil) {
        self.parentFolder = parentFolder
        self.node = node as? BookmarkItemData
        self.profile = profile
        self.logger = logger
        self.bookmarksSaver = bookmarksSaver ?? DefaultBookmarksSaver(profile: profile)
        self.folderFetcher = folderFetcher ?? GroupedDefaultFolderHierarchyFetcher(profile: profile,
                                                                                   rootFolderGUID: BookmarkRoots.RootGUID)
        let folder = GroupedFolder(title: parentFolder.title, guid: parentFolder.guid, indentation: 0)
        folderStructures = [folder]
        selectedFolder = folder
    }

    func shouldShowDisclosureIndicatorForFolder(_ folder: GroupedFolder) -> Bool {
        let shouldShowDisclosureIndicator = folder.guid == selectedFolder?.guid
        return shouldShowDisclosureIndicator && !isFolderCollapsed
    }

    func indentationForFolder(_ folder: GroupedFolder) -> Int {
        if isFolderCollapsed {
            return 0
        }
        return folder.indentation
    }

    @MainActor
    func selectFolder(_ folder: GroupedFolder) {
        isFolderCollapsed.toggle()
        selectedFolder = folder
        if isFolderCollapsed {
            folderStructures = [folder]
            onFolderStatusUpdate?()
        } else {
            getFolderStructure(folder)
        }
    }

    @MainActor
    func createNewFolder() {
        bookmarkCoordinatorDelegate?.showBookmarkDetail(
            bookmarkType: .folder,
            parentBookmarkFolder: parentFolder,
            groupedParentFolderSelector: self)
    }

    private func getFolderStructure(_ selectedFolder: GroupedFolder) {
        Task { @MainActor [weak self] in
            let folders = await self?.folderFetcher.fetchFolders()
            guard let folders else { return }
            self?.folderStructures = Self.insertSectionPlaceholders(into: folders)
            self?.onFolderStatusUpdate?()
        }
    }

    private static func insertSectionPlaceholders(into folders: [GroupedFolder]) -> [GroupedFolder] {
        let mobileFolders = folders.filter { !$0.isDesktopRoot }
        let desktopFolders = folders.filter { $0.isDesktopRoot }
        guard !desktopFolders.isEmpty else { return mobileFolders }

        let mobilePlaceholder = GroupedFolder(title: "",
                                              guid: mobileHeaderPlaceholderGuid,
                                              indentation: placeholderIndentation)
        let desktopPlaceholder = GroupedFolder(title: "",
                                               guid: desktopHeaderPlaceholderGuid,
                                               indentation: placeholderIndentation)
        return [mobilePlaceholder] + mobileFolders + [desktopPlaceholder] + desktopFolders
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
            // There is no way to access the GroupedEditBookmarkViewController without the bookmark already existing,
            // so this call will always try to update an existing bookmark
            let result = await self?.bookmarksSaver.save(bookmark: node,
                                                         parentFolderGUID: selectedFolder.guid)
            // Only update the recent folder pref if it doesn't match what's saved in the pref
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

    @MainActor
    func didFinish() {
        bookmarkCoordinatorDelegate?.didFinish()
    }

    // MARK: GroupedParentFolderSelector

    func selectFolderCreatedFromChild(folder: GroupedFolder) {
        isFolderCollapsed = true
        selectedFolder = folder
        folderStructures = [folder]
        onFolderStatusUpdate?()
    }
}

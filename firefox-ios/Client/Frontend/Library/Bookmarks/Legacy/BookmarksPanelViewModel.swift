// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import Shared

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData
import enum MozillaAppServices.BookmarkRoots

@MainActor
protocol BookmarksPanelViewModelProtocol: Sendable, CanRemoveQuickActionBookmark {
    var profile: Profile { get }
    var bookmarkFolder: FxBookmarkNode? { get }
    var bookmarkFolderGUID: GUID { get }
    var displayedBookmarkNodes: [FxBookmarkNode] { get }
    var isShowingSearchResults: Bool { get }
    var isRootNode: Bool { get }
    var isCurrentFolderEmpty: Bool { get }
    var shouldFlashRow: Bool { get }

    func reloadData(completion: @escaping @MainActor () -> Void)
    func resetSearch()
    func searchBookmarks(query: String, completion: @escaping @MainActor @Sendable () -> Void)
    func moveBookmarkToFolder(bookmark: FxBookmarkNode, withGUID parentFolderGUID: String)
    func remove(bookmark: FxBookmarkNode, afterAsyncRemoval completion: @escaping @MainActor () -> Void)
    func getSiteDetails(for bookmark: FxBookmarkNode, completion: @escaping @MainActor (Site?) -> Void)
    func moveRow(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    func createPinUnpinAction(
        for site: Site,
        isPinned: Bool,
        successHandler: @escaping @MainActor (String) -> Void
    ) -> PhotonRowActions
}

let LocalizedRootBookmarkFolderStrings = [
    BookmarkRoots.MenuFolderGUID: String.BookmarksFolderTitleMenu,
    BookmarkRoots.ToolbarFolderGUID: String.BookmarksFolderTitleToolbar,
    BookmarkRoots.UnfiledFolderGUID: String.BookmarksFolderTitleUnsorted,
    BookmarkRoots.MobileFolderGUID: String.BookmarksFolderTitleMobile,
    LocalDesktopFolder.localDesktopFolderGuid: String.Bookmarks.Menu.DesktopBookmarks
]

@MainActor
final class BookmarksPanelViewModel: BookmarksPanelViewModelProtocol, FeatureFlaggable {
    enum BookmarksSection: Int, CaseIterable {
        case bookmarks
    }

    private var isBookmarksSearchEnabled: Bool {
        featureFlagsProvider.isEnabled(.bookmarksSearchFeature)
    }

    var isRootNode: Bool {
        return bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID
    }

    var isCurrentFolderEmpty: Bool {
        return allBookmarkNodes.isEmpty
    }

    let profile: Profile
    let bookmarkFolderGUID: GUID
    var bookmarkFolder: FxBookmarkNode?
    var isShowingSearchResults = false
    private var currentSearchQuery: String?

    /// Backing data array of all bookmarks
    private var allBookmarkNodes = [FxBookmarkNode]()
    /// Bookmarks filtered via search
    private var filteredBookmarkNodes = [FxBookmarkNode]()

    /// The data source nodes currently displayed: filtered results when searching, otherwise the full bookmark nodes.
    var displayedBookmarkNodes: [FxBookmarkNode] {
        return isShowingSearchResults ? filteredBookmarkNodes : allBookmarkNodes
    }

    var bookmarksHandler: BookmarksHandler
    private var bookmarksSaver: BookmarksSaver
    private var quickActions: QuickActions
    private var hasDesktopFolders = false
    private var flashLastRowOnNextReload = false
    private let logger: Logger

    /// By default our root folder is the mobile folder. Desktop folders are shown in the local desktop folders.
    init(profile: Profile,
         bookmarksHandler: BookmarksHandler,
         bookmarkFolderGUID: GUID = BookmarkRoots.MobileFolderGUID,
         bookmarksSaver: BookmarksSaver? = nil,
         quickActions: QuickActions = QuickActionsImplementation(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.bookmarksHandler = bookmarksHandler
        self.bookmarkFolderGUID = bookmarkFolderGUID
        self.bookmarksSaver = bookmarksSaver ?? DefaultBookmarksSaver(profile: profile)
        self.quickActions = quickActions
        self.logger = logger
    }

    var shouldFlashRow: Bool {
        guard flashLastRowOnNextReload else { return false }
        flashLastRowOnNextReload = false

        return true
    }

    /// Reloads all the bookmarks data (and search results data, if the user is currently searching bookmarks).
    func reloadData(completion: @escaping @MainActor () -> Void) {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        if profile.isShutdown {
            completion()
            return
        }

        // FXIOS-15296: After reloading bookmarks, we should also reload our active search results as well, if applicable.
        // This is because our bookmarks results are fetched recursively and backed by a separate data array.
        // FIXME: FXIOS-15309 This can be improved.
        let completionAfterSetup: @MainActor () -> Void = { [weak self] in
            guard let self else {
                completion()
                return
            }

            // If search results are present, we need to refresh those, too
            if self.isShowingSearchResults, let currentSearchQuery = self.currentSearchQuery {
                self.searchBookmarks(query: currentSearchQuery) {
                    completion()
                }
            } else {
                completion()
            }
        }

        if bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID {
            setupMobileFolderData(completion: completionAfterSetup)
        } else if bookmarkFolderGUID == LocalDesktopFolder.localDesktopFolderGuid {
            setupLocalDesktopFolderData(completion: completionAfterSetup)
        } else {
            setupSubfolderData(completion: completionAfterSetup)
        }
    }

    func didAddBookmarkNode() {
        flashLastRowOnNextReload = true
    }

    func moveRow(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let bookmarkNode = allBookmarkNodes[safe: sourceIndexPath.row] else {
            logger.log("Could not move row from \(sourceIndexPath) to \(destinationIndexPath)",
                       level: .debug,
                       category: .library)
            return
        }

        let newIndex = getNewIndex(from: destinationIndexPath.row)
        _ = bookmarksHandler.updateBookmarkNode(guid: bookmarkNode.guid,
                                                parentGUID: nil,
                                                position: UInt32(newIndex),
                                                title: nil,
                                                url: nil)

        allBookmarkNodes.remove(at: sourceIndexPath.row)
        allBookmarkNodes.insert(bookmarkNode, at: destinationIndexPath.row)
    }

    func getSiteDetails(for bookmark: FxBookmarkNode, completion: @escaping @MainActor (Site?) -> Void) {
        guard let bookmarkItem = bookmark as? BookmarkItemData else {
            logger.log("Could not get site details for bookmark",
                       level: .debug,
                       category: .library)
            completion(nil)
            return
        }

        checkIfPinnedURL(bookmarkItem.url) { [weak self] isPinned in
            guard let site = self?.createSite(isPinned: isPinned, bookmarkItem: bookmarkItem) else { return }
            completion(site)
        }
    }

    func createPinUnpinAction(
        for site: Site,
        isPinned: Bool,
        successHandler: @escaping @MainActor (String) -> Void
    ) -> PhotonRowActions {
        return SingleActionViewModel(
            title: isPinned ? .Bookmarks.Menu.RemoveFromShortcutsTitle : .AddToShortcutsActionTitle,
            iconString: isPinned ? StandardImageIdentifiers.Large.pinSlash : StandardImageIdentifiers.Large.pin,
            tapHandler: { [weak self] _ in
                guard let profile = self?.profile, let logger = self?.logger else { return }
                let action = isPinned
                ? profile.pinnedSites.removeFromPinnedTopSites(site)
                : profile.pinnedSites.addPinnedTopSite(site)

                action.uponQueue(.main) { result in
                    // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
                    MainActor.assumeIsolated {
                        if result.isSuccess {
                            let message: String = isPinned
                            ? .LegacyAppMenu.RemovePinFromShortcutsConfirmMessage
                            : .LegacyAppMenu.AddPinToShortcutsConfirmMessage
                            successHandler(message)
                        } else {
                            let logMessage = isPinned ? "Could not remove pinned site" : "Could not add pinne site"
                            logger.log(logMessage, level: .debug, category: .library)
                        }
                    }
                }
            }
        ).items
    }

    // MARK: - Search

    /// Recursively searches all bookmarks under the current folder (and its subfolders)
    /// for items whose title or URL contains the given query string (case-insensitive).
    func searchBookmarks(query: String, completion: @escaping @MainActor () -> Void) {
        guard !query.isEmpty else {
            isShowingSearchResults = true
            filteredBookmarkNodes = []
            completion()
            return
        }

        currentSearchQuery = query

        bookmarksHandler
            .getBookmarksTree(rootGUID: bookmarkFolderGUID, recursive: true)
            .uponQueue(.main) { [weak self] result in
                // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
                MainActor.assumeIsolated {
                    switch result {
                    case .success(let nodeData):
                        guard let folderData = nodeData as? BookmarkFolderData else {
                            self?.logger.log("Search bookmarks tree fetch failed",
                                             level: .debug,
                                             category: .library)
                            completion()
                            return
                        }

                        let lowercasedQuery = query.lowercased()
                        var matches = [FxBookmarkNode]()
                        self?.collectMatchingBookmarks(from: folderData,
                                                       query: lowercasedQuery,
                                                       results: &matches)

                        self?.isShowingSearchResults = true
                        self?.filteredBookmarkNodes = matches

                        completion()

                    case .failure(let error):
                        self?.logger.log("Search bookmarks tree fetch error: \(error)",
                                         level: .debug,
                                         category: .library)

                        self?.isShowingSearchResults = true
                        self?.filteredBookmarkNodes = []
                        completion()
                    }
                }
            }
    }

    /// Recursively traverses the bookmark tree collecting BookmarkItemData nodes
    /// whose title or URL matches the search query.
    private func collectMatchingBookmarks(from folder: BookmarkFolderData,
                                          query: String,
                                          results: inout [FxBookmarkNode]) {
        guard let children = folder.children else { return }

        for child in children {
            if let item = child as? BookmarkItemData {
                if item.title.lowercased().contains(query) ||
                    item.url.lowercased().contains(query) {
                    results.append(item)
                }
            } else if let subfolder = child as? BookmarkFolderData {
                collectMatchingBookmarks(from: subfolder, query: query, results: &results)
            }
            // Skip separators
        }
    }

    // MARK: - Private

    /// Since we have a Local Desktop folder that isn't referenced in A-S under the mobile folder,
    /// we need to account for this when saving bookmark index in A-S. This is done by subtracting
    /// the Local Desktop Folder number of rows it takes to the actual index.
    func getNewIndex(from index: Int) -> Int {
        guard bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID, hasDesktopFolders else {
            return max(index, 0)
        }

        // Ensure we don't return lower than 0
        return max(index - LocalDesktopFolder.numberOfRowsTaken, 0)
    }

    private func setupMobileFolderData(completion: @escaping @MainActor () -> Void) {
        bookmarksHandler
            .getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: false)
            .uponQueue(.main) { result in
                // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
                MainActor.assumeIsolated {
                    guard let mobileFolder = result.successValue as? BookmarkFolderData else {
                        self.logger.log("Mobile folder data setup failed \(String(describing: result.failureValue))",
                                        level: .debug,
                                        category: .library)
                        self.setErrorCase()
                        completion()
                        return
                    }

                    self.bookmarkFolder = mobileFolder
                    self.allBookmarkNodes = mobileFolder.fxChildren ?? []

                    self.createDesktopBookmarksFolder(completion: completion)
                }
            }
    }

    /// Local desktop folder data is a folder that only exists locally in the application
    /// It contains the three desktop folder of "unfiled", "menu" and "toolbar"
    private func setupLocalDesktopFolderData(completion: () -> Void) {
        let unfiled = LocalDesktopFolder(forcedGuid: BookmarkRoots.UnfiledFolderGUID)
        let toolbar = LocalDesktopFolder(forcedGuid: BookmarkRoots.ToolbarFolderGUID)
        let menu = LocalDesktopFolder(forcedGuid: BookmarkRoots.MenuFolderGUID)

        self.bookmarkFolder = nil
        self.allBookmarkNodes = [unfiled, toolbar, menu]
        completion()
    }

    /// Subfolder data case happens when we select a folder created by a user
    private func setupSubfolderData(completion: @escaping @MainActor () -> Void) {
        bookmarksHandler.getBookmarksTree(rootGUID: bookmarkFolderGUID,
                                          recursive: false)
        .uponQueue(.main) { result in
            // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
            MainActor.assumeIsolated {
                guard let folder = result.successValue as? BookmarkFolderData else {
                    self.logger.log("Subfolder data setup failed \(String(describing: result.failureValue))",
                                    level: .debug,
                                    category: .library)
                    self.setErrorCase()
                    completion()
                    return
                }

                self.bookmarkFolder = folder
                self.allBookmarkNodes = folder.fxChildren ?? []

                completion()
            }
        }
    }

    /// Error case at the moment is setting data to nil and showing nothing
    private func setErrorCase() {
        self.bookmarkFolder = nil
        self.allBookmarkNodes = []
    }

    // Create a local "Desktop bookmarks" folder only if there exists a bookmark in one of it's nested
    // subfolders
    private func createDesktopBookmarksFolder(completion: @escaping @MainActor () -> Void) {
        bookmarksHandler.countBookmarksInTrees(folderGuids: BookmarkRoots.DesktopRoots.map { $0 }) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let bookmarkCount):
                    if bookmarkCount > 0 {
                        self.hasDesktopFolders = true
                        let desktopFolder = LocalDesktopFolder()
                        self.allBookmarkNodes.insert(desktopFolder, at: 0)
                    } else {
                        self.hasDesktopFolders = false
                    }
                case .failure(let error):
                    self.logger.log("Error counting bookmarks: \(error)", level: .debug, category: .library)
                }
                completion()
            }
        }
    }

    private func checkIfPinnedURL(
        _ url: String,
        completion: @escaping @MainActor  (Bool) -> Void
    ) {
        profile.pinnedSites.isPinnedTopSite(url)
            .uponQueue(.main) { result in
                // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
                MainActor.assumeIsolated {
                    completion(result.successValue ?? false)
                }
            }
    }

    private func createSite(isPinned: Bool, bookmarkItem: BookmarkItemData) -> Site {
        guard isPinned else {
            return Site.createBasicSite(
                url: bookmarkItem.url,
                title: bookmarkItem.title,
                isBookmarked: true
            )
        }
        return Site.createPinnedSite(
            url: bookmarkItem.url,
            title: bookmarkItem.title,
            isGooglePinnedTile: false
        )
    }

    func resetSearch() {
        isShowingSearchResults = false
        filteredBookmarkNodes.removeAll()
    }

    func removeBookmarkLocally(bookmark: FxBookmarkNode) {
        // Immediately remove the bookmark from backing arrays and search matches, if needed (for UI responsiveness)
        allBookmarkNodes.removeAll(where: { $0.guid == bookmark.guid })
        filteredBookmarkNodes.removeAll(where: { $0.guid == bookmark.guid })
    }

    /// Deletes the bookmark. Deletion of the bookmark in places happens asynchronously, but tableView source arrays are
    /// updated immediately for UI responsiveness.
    /// - Parameters:
    ///   - bookmark: The bookmark to delete.
    ///   - completion: The completion handler to call after the bookmark has been asynchronously removed from the backing
    ///                 store.
    func remove(bookmark: FxBookmarkNode, afterAsyncRemoval completion: @escaping @MainActor () -> Void) {
        let removalCompletion: @MainActor () -> Void = { [weak self] in
            if let self, self.isBookmarksSearchEnabled, self.isShowingSearchResults {
                // Reload the bookmarks tree for the current folder. If a bookmark was deleted via search, there is a chance
                // a subfolder becomes empty that was previously non-empty. We need to know whether folders in the current
                // folder contain bookmarks or not because we show an alert when deleting folders with non-empty contents
                // (see FXIOS-15296).
                //
                // Note: A race condition exists where the user might try to delete a folder before this refresh completes,
                // since we optimistically update the UI but can't synchronously update the local bookmarks tree copy.
                // FIXME: FXIOS-15309
                self.reloadData {
                    completion()
                }
            } else {
                completion()
            }
        }
        // Remove the bookmark from places (async background work)
        bookmarksHandler.deleteBookmarkNode(guid: bookmark.guid).uponQueue(DispatchQueue.main) { _ in
            // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
            MainActor.assumeIsolated { [weak self] in
                guard let self else { return }

                // Remove this bookmark from quick actions
                Self.removeBookmarkShortcut(withBookmarksHandler: self.bookmarksHandler, withQuickActions: self.quickActions)

                // Remove this bookmark out of recent places
                if let recentBookmarkFolderGuid = self.profile.prefs.stringForKey(PrefsKeys.RecentBookmarkFolder) {
                    self.profile.places.getBookmark(guid: recentBookmarkFolderGuid).uponQueue(.main) { node in
                        // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
                        MainActor.assumeIsolated {
                            guard let nodeValue = node.successValue, nodeValue == nil else {
                                removalCompletion()
                                return
                            }

                            self.profile.prefs.removeObjectForKey(PrefsKeys.RecentBookmarkFolder)
                            removalCompletion()
                        }
                    }
                } else {
                    removalCompletion()
                }
            }
        }

        // Immediately remove the bookmark from backing arrays and search matches, if needed (for UI responsiveness)
        removeBookmarkLocally(bookmark: bookmark)
    }

    /// Updates the bookmark with a new parent GUID. Update of bookmark in places happens asynchronously, but tableView
    /// source arrays are updated immediately for UI responsiveness.
    func moveBookmarkToFolder(bookmark: FxBookmarkNode, withGUID parentFolderGUID: String) {
        // Save the bookmark updates (async)
        Task {
            _ = await bookmarksSaver.save(bookmark: bookmark, parentFolderGUID: parentFolderGUID)
        }

        // When a bookmark is dragged and dropped into another folder, we should remove it from the current view of bookmarks
        // Immediately update the UI for responsiveness.
        removeBookmarkLocally(bookmark: bookmark)
    }
}

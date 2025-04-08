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

final class BookmarksPanelViewModel: BookmarksRefactorFeatureFlagProvider {
    enum BookmarksSection: Int, CaseIterable {
        case bookmarks
    }

    var isRootNode: Bool {
        return bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID
    }

    let profile: Profile
    let bookmarkFolderGUID: GUID
    var bookmarkFolder: FxBookmarkNode?
    var bookmarkNodes = [FxBookmarkNode]()
    private var hasDesktopFolders = false
    private var bookmarksHandler: BookmarksHandler
    private var flashLastRowOnNextReload = false
    private var mainQueue: DispatchQueueInterface
    private var logger: Logger

    /// By default our root folder is the mobile folder. Desktop folders are shown in the local desktop folders.
    init(profile: Profile,
         bookmarksHandler: BookmarksHandler,
         bookmarkFolderGUID: GUID = BookmarkRoots.MobileFolderGUID,
         mainQueue: DispatchQueueInterface = DispatchQueue.main,
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.bookmarksHandler = bookmarksHandler
        self.bookmarkFolderGUID = bookmarkFolderGUID
        self.mainQueue = mainQueue
        self.logger = logger
    }

    var shouldFlashRow: Bool {
        guard flashLastRowOnNextReload else { return false }
        flashLastRowOnNextReload = false

        return true
    }

    func reloadData(completion: @escaping () -> Void) {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        if profile.isShutdown {
            completion()
            return
        }

        if bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID {
            setupMobileFolderData(completion: completion)
        } else if bookmarkFolderGUID == LocalDesktopFolder.localDesktopFolderGuid {
            setupLocalDesktopFolderData(completion: completion)
        } else {
            setupSubfolderData(completion: completion)
        }
    }

    func didAddBookmarkNode() {
        flashLastRowOnNextReload = true
    }

    func moveRow(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let bookmarkNode = bookmarkNodes[safe: sourceIndexPath.row] else {
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

        bookmarkNodes.remove(at: sourceIndexPath.row)
        bookmarkNodes.insert(bookmarkNode, at: destinationIndexPath.row)
    }

    func getSiteDetails(for indexPath: IndexPath, completion: @escaping (Site?) -> Void) {
        guard let bookmarkNode = bookmarkNodes[safe: indexPath.row],
              let bookmarkItem = bookmarkNode as? BookmarkItemData
        else {
            logger.log("Could not get site details for indexPath \(indexPath)",
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
        successHandler: @escaping (String) -> Void
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
        ).items
    }

    // MARK: - Private

    /// Since we have a Local Desktop folder that isn't referenced in A-S under the mobile folder,
    /// we need to account for this when saving bookmark index in A-S. This is done by subtracting
    /// the Local Desktop Folder number of rows it takes to the actual index.
    func getNewIndex(from index: Int) -> Int {
        var isDesktopFolderPresent = false
        if isBookmarkRefactorEnabled && hasDesktopFolders {
            isDesktopFolderPresent = true
        } else if isBookmarkRefactorEnabled == false {
            isDesktopFolderPresent = true
        }
        guard bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID, isDesktopFolderPresent else {
            return max(index, 0)
        }

        // Ensure we don't return lower than 0
        return max(index - LocalDesktopFolder.numberOfRowsTaken, 0)
    }

    private func setupMobileFolderData(completion: @escaping () -> Void) {
        bookmarksHandler
            .getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: false)
            .uponQueue(.main) { result in
                guard let mobileFolder = result.successValue as? BookmarkFolderData else {
                    self.logger.log("Mobile folder data setup failed \(String(describing: result.failureValue))",
                                    level: .debug,
                                    category: .library)
                    self.setErrorCase()
                    completion()
                    return
                }

                self.bookmarkFolder = mobileFolder
                self.bookmarkNodes = mobileFolder.fxChildren ?? []

                self.createDesktopBookmarksFolder(completion: completion)
            }
    }

    /// Local desktop folder data is a folder that only exists locally in the application
    /// It contains the three desktop folder of "unfiled", "menu" and "toolbar"
    private func setupLocalDesktopFolderData(completion: () -> Void) {
        let unfiled = LocalDesktopFolder(forcedGuid: BookmarkRoots.UnfiledFolderGUID)
        let toolbar = LocalDesktopFolder(forcedGuid: BookmarkRoots.ToolbarFolderGUID)
        let menu = LocalDesktopFolder(forcedGuid: BookmarkRoots.MenuFolderGUID)

        self.bookmarkFolder = nil
        self.bookmarkNodes = [unfiled, toolbar, menu]
        completion()
    }

    /// Subfolder data case happens when we select a folder created by a user
    private func setupSubfolderData(completion: @escaping () -> Void) {
        bookmarksHandler.getBookmarksTree(rootGUID: bookmarkFolderGUID,
                                          recursive: false).uponQueue(.main) { result in
            guard let folder = result.successValue as? BookmarkFolderData else {
                self.logger.log("Sublfolder data setup failed \(String(describing: result.failureValue))",
                                level: .debug,
                                category: .library)
                self.setErrorCase()
                completion()
                return
            }

            self.bookmarkFolder = folder
            self.bookmarkNodes = folder.fxChildren ?? []

            completion()
        }
    }

    /// Error case at the moment is setting data to nil and showing nothing
    private func setErrorCase() {
        self.bookmarkFolder = nil
        self.bookmarkNodes = []
    }

    // Create a local "Desktop bookmarks" folder only if there exists a bookmark in one of it's nested
    // subfolders
    private func createDesktopBookmarksFolder(completion: @escaping () -> Void) {
        self.bookmarksHandler.countBookmarksInTrees(folderGuids: BookmarkRoots.DesktopRoots.map { $0 }) { result in
            switch result {
            case .success(let bookmarkCount):
                if bookmarkCount > 0 || !self.isBookmarkRefactorEnabled {
                    self.hasDesktopFolders = true
                    let desktopFolder = LocalDesktopFolder()
                    self.mainQueue.async {
                        self.bookmarkNodes.insert(desktopFolder, at: 0)
                    }
                } else {
                    self.hasDesktopFolders = false
                }
            case .failure(let error):
                self.logger.log("Error counting bookmarks: \(error)", level: .debug, category: .library)
            }
            completion()
        }
    }

    private func checkIfPinnedURL(_ url: String, queue: DispatchQueue = .main, completion: @escaping (Bool) -> Void ) {
        profile.pinnedSites.isPinnedTopSite(url)
            .uponQueue(queue) { result in
                completion(result.successValue ?? false)
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
}

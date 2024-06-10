// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import Shared

import class MozillaAppServices.BookmarkFolderData
import enum MozillaAppServices.BookmarkRoots

class BookmarksPanelViewModel {
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
    private var bookmarksHandler: BookmarksHandler
    private var flashLastRowOnNextReload = false
    private var logger: Logger

    /// By default our root folder is the mobile folder. Desktop folders are shown in the local desktop folders.
    init(profile: Profile,
         bookmarksHandler: BookmarksHandler,
         bookmarkFolderGUID: GUID = BookmarkRoots.MobileFolderGUID,
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.bookmarksHandler = bookmarksHandler
        self.bookmarkFolderGUID = bookmarkFolderGUID
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

    // MARK: - Private

    /// Since we have a Local Desktop folder that isn't referenced in A-S under the mobile folder,
    /// we need to account for this when saving bookmark index in A-S. This is done by subtracting
    /// the Local Desktop Folder number of rows it takes to the actual index.
    func getNewIndex(from index: Int) -> Int {
        guard bookmarkFolderGUID == BookmarkRoots.MobileFolderGUID else {
            return index
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

                let desktopFolder = LocalDesktopFolder()
                self.bookmarkNodes.insert(desktopFolder, at: 0)

                completion()
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
}

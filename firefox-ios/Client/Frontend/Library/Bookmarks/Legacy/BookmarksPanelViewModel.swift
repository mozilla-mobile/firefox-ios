// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import Shared
import Ecosia

/* Ecosia: Import all of MozillaAppServices for legacy code usage
import class MozillaAppServices.BookmarkFolderData
import enum MozillaAppServices.BookmarkRoots
 */
import MozillaAppServices

/* Ecosia: Inherit NSObject so it can extend UIDocumentPickerDelegate
class BookmarksPanelViewModel {
 */
class BookmarksPanelViewModel: NSObject {
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
    // Ecosia: Import Bookmarks Helper
    private let bookmarksExchange: BookmarksExchangable
    private var documentPickerPresentingViewController: UIViewController?
    private var onImportDoneHandler: ((URL?, Error?) -> Void)?
    private var onExportDoneHandler: ((Error?) -> Void)?

    /// By default our root folder is the mobile folder. Desktop folders are shown in the local desktop folders.
    init(profile: Profile,
         bookmarksHandler: BookmarksHandler,
         bookmarkFolderGUID: GUID = BookmarkRoots.MobileFolderGUID,
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.bookmarksHandler = bookmarksHandler
        self.bookmarkFolderGUID = bookmarkFolderGUID
        self.logger = logger
        // Ecosia: BookmarksExchange
        self.bookmarksExchange = BookmarksExchange(profile: profile)
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

                /* Ecosia: remove desktop folder
                let desktopFolder = LocalDesktopFolder()
                self.bookmarkNodes.insert(desktopFolder, at: 0)
                 */
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

// Ecosia: Import Bookmarks Helper
extension BookmarksPanelViewModel {

    func bookmarkExportSelected(in viewController: LegacyBookmarksPanel, onDone: @escaping (Error?) -> Void) {
        Task {
            self.onExportDoneHandler = onDone
            do {
                let bookmarks = try await getBookmarksForExport()
                try await bookmarksExchange.export(bookmarks: bookmarks, in: viewController, barButtonItem: viewController.moreButton)
                await notifyExportDone(nil)
            } catch {
                await notifyExportDone(error)
            }
        }
    }

    func bookmarkImportSelected(in viewController: UIViewController, onDone: @escaping (URL?, Error?) -> Void) {
        self.documentPickerPresentingViewController = viewController
        self.onImportDoneHandler = onDone
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.html"], in: .open)
        documentPicker.allowsMultipleSelection = false
        // Ecosia: Theming
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        let theme = themeManager.getCurrentTheme(for: viewController.view.currentWindowUUID)
        documentPicker.view.tintColor = theme.colors.ecosia.buttonBackgroundPrimary
        documentPicker.delegate = self
        viewController.present(documentPicker, animated: true)
    }

    // MARK: - Private
    private func getBookmarksForExport() async throws -> [Ecosia.BookmarkItem] {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                return continuation.resume(returning: [])
            }

            profile.places
                .getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: true)
                .uponQueue(.main) { result in
                    guard let mobileFolder = result.successValue as? BookmarkFolderData else {
                        self.setErrorCase()
                        return
                    }

                    self.bookmarkFolder = mobileFolder
                    let bookmarkNodes = mobileFolder.fxChildren ?? []

                    let items: [Ecosia.BookmarkItem] = bookmarkNodes
                        .compactMap { $0 as? BookmarkNodeData }
                        .compactMap { bookmarkNode in
                            self.exportNode(bookmarkNode)
                        }

                    continuation.resume(returning: items)
                }
        }
    }

    private func exportNode(_ node: BookmarkNodeData) -> Ecosia.BookmarkItem? {
        if let folder = node as? BookmarkFolderData {
            return .folder(folder.title, folder.children?.compactMap { exportNode($0) } ?? [], .empty)
        } else if let bookmark = node as? BookmarkItemData {
            return .bookmark(bookmark.title, bookmark.url, .empty)
        }
        assertionFailure("This should not happen")
        return nil
    }

    @MainActor
    private func notifyExportDone(_ error: Error?) {
        onExportDoneHandler?(error)
    }
}

extension BookmarksPanelViewModel: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.onImportDoneHandler?(nil, nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard
            let firstHtmlUrl = urls.first,
            let viewController = documentPickerPresentingViewController
        else { return }
        handlePickedUrl(firstHtmlUrl, in: viewController)
    }

    func handlePickedUrl(_ url: URL, in viewController: UIViewController) {
        let scopedResourceAccess = url.startAccessingSecurityScopedResource()
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { url in
            Task {
                defer {
                    if scopedResourceAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                do {
                    try await bookmarksExchange.import(from: url, in: viewController)
                    await notifyImportDone(url, nil)
                } catch {
                    await notifyImportDone(url, error)
                }
            }
        }
        if let error = error {
            Task {
                await notifyImportDone(url, error)
            }
        }
    }

    @MainActor
    private func notifyImportDone(_ url: URL, _ error: Error?) {
        onImportDoneHandler?(url, error)
    }
}

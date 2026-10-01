// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

// FIXME: FXIOS-14160 Make EditFolderViewModel actually Sendable
class EditFolderViewModel: @unchecked Sendable {
    private let profile: Profile
    private let logger: Logger
    private let parentFolder: FxBookmarkNode
    private var folder: FxBookmarkNode?
    private let bookmarkSaver: BookmarksSaver
    let isSavingTabs: Bool
    private var bookmarksToSave: ArraySlice<BookmarkItemData>
    private var createdFolderGUID: String?
    private(set) var saveSucceeded = false
    private(set) var isSaving = false
    var onSaveFailed: VoidReturnCallback?
    private let folderFetcher: FolderHierarchyFetcher
    private(set) var selectedFolder: Folder?
    private(set) var folderStructures = [Folder]()
    private(set) var isFolderCollapsed = true
    private var isNewFolderView: Bool {
        return folder == nil
    }

    var onFolderStatusUpdate: VoidReturnCallback?
    var onBookmarkSaved: VoidReturnCallback?
    weak var parentFolderSelector: ParentFolderSelector?

    var controllerTitle: String {
        return isNewFolderView ? .BookmarksNewFolder : .BookmarksEditFolder
    }
    var editedFolderTitle: String? {
        return folder?.title
    }

    init(profile: Profile,
         logger: Logger = DefaultLogger.shared,
         parentFolder: FxBookmarkNode,
         folder: FxBookmarkNode?,
         bookmarkSaver: BookmarksSaver? = nil,
         folderFetcher: FolderHierarchyFetcher? = nil,
         bookmarksToSave: [BookmarkItemData] = []) {
        self.isSavingTabs = !bookmarksToSave.isEmpty
        self.bookmarksToSave = bookmarksToSave[...]
        self.profile = profile
        self.logger = logger
        self.parentFolder = parentFolder
        self.folder = folder
        self.bookmarkSaver = bookmarkSaver ?? DefaultBookmarksSaver(profile: profile)
        self.folderFetcher = folderFetcher ?? DefaultFolderHierarchyFetcher(profile: profile,
                                                                            rootFolderGUID: BookmarkRoots.RootGUID)
        let folder = Folder(title: parentFolder.title, guid: parentFolder.guid, indentation: 0)
        folderStructures = [folder]
        selectedFolder = folder
    }

    func shouldShowDisclosureIndicator(isFolderSelected: Bool) -> Bool {
        return isFolderSelected && !isFolderCollapsed
    }

    @MainActor
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
            guard let self else { return }
            let folders = await folderFetcher.fetchFolders(excludedGuids: [createdFolderGUID ?? folder?.guid ?? ""])
            folderStructures = folders
            onFolderStatusUpdate?()
        }
    }

    func updateFolderTitle(_ title: String) {
        if let folderToUpdate = folder as? BookmarkFolderData {
            folder = folderToUpdate.copy(withTitle: title)
        } else {
            folder = BookmarkFolderData(guid: "",
                                        dateAdded: 0,
                                        lastModified: 0,
                                        parentGUID: nil,
                                        position: 0,
                                        title: title,
                                        childGUIDs: [],
                                        children: nil)
        }
    }

    @discardableResult
    @MainActor
    func save() -> Task<Void, Never>? {
        guard let folder, !folder.title.isEmpty else { return nil }
        if isSavingTabs {
            guard !isSaving, !folder.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        }
        isSaving = true
        saveSucceeded = false
        let selectedFolderGUID = selectedFolder?.guid ?? parentFolder.guid
        return Task { @MainActor in
            await saveFolderAndBookmarks(folder: folder, parentGUID: selectedFolderGUID)
        }
    }

    @MainActor
    private func saveFolderAndBookmarks(folder: FxBookmarkNode, parentGUID: String) async {
        defer { isSaving = false }
        // Creates or updates the folder
        let result: Result<GUID?, Error>
        if let createdFolderGUID {
            let savedFolder = BookmarkFolderData(guid: createdFolderGUID,
                                                 dateAdded: 0,
                                                 lastModified: 0,
                                                 parentGUID: parentGUID,
                                                 position: folder.position,
                                                 title: folder.title,
                                                 childGUIDs: [],
                                                 children: nil)
            let updateResult = await bookmarkSaver.save(bookmark: savedFolder, parentFolderGUID: parentGUID)
            result = updateResult.map { _ in createdFolderGUID }
        } else {
            result = await bookmarkSaver.save(bookmark: folder, parentFolderGUID: parentGUID)
        }
        switch result {
        case .success(let guid):
            // A nil guid indicates a bookmark update, not creation
            guard let guid else {
                if !bookmarksToSave.isEmpty {
                    onSaveFailed?()
                    return
                }
                break
            }
            if isSavingTabs { createdFolderGUID = guid }
            while let bookmark = bookmarksToSave.first {
                let bookmarkResult = await bookmarkSaver.save(bookmark: bookmark, parentFolderGUID: guid)
                guard case .success = bookmarkResult else {
                    onSaveFailed?()
                    return
                }
                bookmarksToSave.removeFirst()
            }
            profile.prefs.setString(guid, forKey: PrefsKeys.RecentBookmarkFolder)

            // When the folder edit view is a child of the edit bookmark view, the newly created folder
            // should be selected
            let folderCreated = Folder(title: folder.title, guid: guid, indentation: 0)
            parentFolderSelector?.selectFolderCreatedFromChild(folder: folderCreated)
        case .failure(let error):
            self.logger.log("Failed to save folder: \(error)", level: .warning, category: .library)
            if isSavingTabs {
                onSaveFailed?()
                return
            }
        }

        saveSucceeded = true
        onBookmarkSaved?()
    }
}

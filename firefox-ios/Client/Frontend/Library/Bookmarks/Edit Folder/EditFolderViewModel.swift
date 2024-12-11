// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

class EditFolderViewModel {
    private let profile: Profile
    private let logger: Logger
    private let parentFolder: FxBookmarkNode
    private var folder: FxBookmarkNode?
    private let bookmarkSaver: BookmarksSaver
    private let folderFetcher: FolderHierarchyFetcher
    private(set) var selectedFolder: Folder?
    private(set) var folderStructures = [Folder]()
    private(set) var isFolderCollapsed = true

    var onFolderStatusUpdate: VoidReturnCallback?
    var onBookmarkSaved: VoidReturnCallback?

    var controllerTitle: String {
        return folder == nil ? .BookmarksNewFolder : .BookmarksEditFolder
    }
    var editedFolderTitle: String? {
        return folder?.title
    }

    init(profile: Profile,
         logger: Logger = DefaultLogger.shared,
         parentFolder: FxBookmarkNode,
         folder: FxBookmarkNode?,
         bookmarkSaver: BookmarksSaver? = nil,
         folderFetcher: FolderHierarchyFetcher? = nil) {
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

    private func title(for folder: BookmarkFolderData) -> String {
        return LocalizedRootBookmarkFolderStrings[folder.guid] ?? folder.title
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
            let folders = await self?.folderFetcher.fetchFolders().filter {
                // exclude the current editing folder from the folder structure
                return $0.guid != self?.folder?.guid
            }
            guard let folders else { return }
            self?.folderStructures = folders
            self?.onFolderStatusUpdate?()
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

    func save() {
        guard let folder else { return }
        let selectedFolderGUID = selectedFolder?.guid ?? parentFolder.guid
        Task { @MainActor in
                let result = await bookmarkSaver.save(bookmark: folder, parentFolderGUID: selectedFolderGUID)
                switch result {
                case .success(let saveResult):
                    switch saveResult {
                    case .guid(let guid):
                        profile.prefs.setString(guid, forKey: PrefsKeys.BookmarkSaveToFolder)
                    default:
                        break
                    }
                case .failure(let error):
                    self.logger.log("Failed to save: \(error)", level: .warning, category: .library)
                }

                onBookmarkSaved?()
        }
    }
}

extension BookmarkFolderData {
    func copy(withTitle title: String) -> BookmarkFolderData {
        return BookmarkFolderData(guid: guid,
                                  dateAdded: dateAdded,
                                  lastModified: lastModified,
                                  parentGUID: parentGUID,
                                  position: position,
                                  title: title,
                                  childGUIDs: childGUIDs,
                                  children: children)
    }
}

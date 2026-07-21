// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

// FIXME: FXIOS-14160 Make EditFolderViewModel actually Sendable
class NewEditFolderViewModel: @unchecked Sendable {
    private static let mobileExpandedByDefault = true
    private static let desktopExpandedByDefault = false

    private let profile: Profile
    private let logger: Logger
    private let parentFolder: FxBookmarkNode
    private var folder: FxBookmarkNode?
    private let bookmarkSaver: BookmarksSaver
    private let folderFetcher: NewFolderHierarchyFetcher
    private(set) var selectedFolder: NewFolder?
    private(set) var folderGroups = [FolderGroup]()
    private(set) var isBrowsingFolders = false
    private var isNewFolderView: Bool {
        return folder == nil
    }

    var onFolderStatusUpdate: VoidReturnCallback?
    var onGroupExpansionUpdate: ((Int) -> Void)?
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
         folderFetcher: NewFolderHierarchyFetcher? = nil) {
        self.profile = profile
        self.logger = logger
        self.parentFolder = parentFolder
        self.folder = folder
        self.bookmarkSaver = bookmarkSaver ?? DefaultBookmarksSaver(profile: profile)
        self.folderFetcher = folderFetcher ?? NewDefaultFolderHierarchyFetcher(profile: profile,
                                                                               rootFolderGUID: BookmarkRoots.RootGUID)
        selectedFolder = NewFolder(title: parentFolder.title, guid: parentFolder.guid, indentation: 0)
    }

    private func loadFolderGroups() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let folders = await self.folderFetcher.fetchFolders(excludedGuids: [self.folder?.guid ?? ""])
            let previousExpansionByID = Dictionary(uniqueKeysWithValues: self.folderGroups.map { ($0.id, $0.isExpanded) })

            var newGroups = FolderGroup.makeGroups(
                from: folders,
                mobileTitle: .Bookmarks.Menu.EditBookmarkMobileGroupLabel,
                desktopTitle: .Bookmarks.Menu.EditBookmarkDesktopGroupLabel,
                mobileExpandedByDefault: Self.mobileExpandedByDefault,
                desktopExpandedByDefault: Self.desktopExpandedByDefault
            )
            for index in newGroups.indices {
                if let previousValue = previousExpansionByID[newGroups[index].id] {
                    newGroups[index].isExpanded = previousValue
                }
            }

            self.folderGroups = newGroups
            self.onFolderStatusUpdate?()
        }
    }

    @MainActor
    func beginBrowsingFolders() {
        isBrowsingFolders = true
        loadFolderGroups()
    }

    @MainActor
    func selectFolder(_ folder: NewFolder) {
        selectedFolder = folder
        isBrowsingFolders = false
        onFolderStatusUpdate?()
    }

    @MainActor
    func toggleGroupExpansion(at index: Int) {
        guard folderGroups.indices.contains(index) else { return }
        folderGroups[index].isExpanded.toggle()
        onGroupExpansionUpdate?(index)
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
    func save() -> Task<Void, Never>? {
        guard let folder, !folder.title.isEmpty else { return nil }
        let selectedFolderGUID = selectedFolder?.guid ?? parentFolder.guid
        return Task { @MainActor in
            // Creates or updates the folder
            let result = await bookmarkSaver.save(bookmark: folder, parentFolderGUID: selectedFolderGUID)
            switch result {
            case .success(let guid):
                // A nil guid indicates a bookmark update, not creation
                guard let guid else { break }
                profile.prefs.setString(guid, forKey: PrefsKeys.RecentBookmarkFolder)

                // When the folder edit view is a child of the edit bookmark view, the newly created folder
                // should be selected
                let folderCreated = Folder(title: folder.title, guid: guid, indentation: 0)
                parentFolderSelector?.selectFolderCreatedFromChild(folder: folderCreated)
            case .failure(let error):
                self.logger.log("Failed to save folder: \(error)", level: .warning, category: .library)
            }

            onBookmarkSaved?()
        }
    }
}

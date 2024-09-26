// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

class EditBookmarkViewModel {
    init(parentFolder: FxBookmarkNode,
         node: FxBookmarkNode,
         profile: Profile) {
        self.parentFolder = parentFolder
        self.node = node
        self.profile = profile
        guard let parentFolder = parentFolder as? BookmarkFolderData else { return }
        folderStructures.append(Folder(title: title(for: parentFolder),
                                       guid: parentFolder.guid,
                                       indentation: 0,
                                       isSelected: true))
    }

    struct Folder {
        let title: String
        let guid: String
        let indentation: Int
        let isSelected: Bool
    }
    typealias VoidReturnCallback = () -> Void

    let parentFolder: FxBookmarkNode
    let node: FxBookmarkNode
    let profile: Profile
    private lazy var updatedTitle = node.title
    private lazy var updatedUrl = (node as? BookmarkItemData)?.url
    private var isFolderCollapsed = true
    private(set) var folderStructures: [Folder] = []
    var onFolderStatusUpdate: VoidReturnCallback?
    var onBookmarkSaved: VoidReturnCallback?

    func shouldShowDisclosureIndicator(isFolderSelected: Bool) -> Bool {
        return isFolderSelected && !isFolderCollapsed
    }

    func selectFolder(_ folder: Folder) {
        isFolderCollapsed.toggle()
        if isFolderCollapsed {
            folderStructures = [folder]
            onFolderStatusUpdate?()
        } else {
            getFolderStructure(folder)
        }
    }

    private func getFolderStructure(_ selectedFolder: Folder) {
        profile.places.getBookmarksTree(rootGUID: BookmarkRoots.RootGUID,
                                        recursive: true).uponQueue(.main) { [weak self] data in
            defer {
                self?.onFolderStatusUpdate?()
            }
            guard let rootFolder = data.successValue as? BookmarkFolderData else { return }
            let childrenFolders = rootFolder.children?.compactMap {
                return $0 as? BookmarkFolderData
            }
            self?.folderStructures.removeAll(keepingCapacity: true)
            for folder in childrenFolders ?? [] {
                self?.recursiveAddSubFolders(folder, selectedFolderGUID: selectedFolder.guid)
            }
        }
    }

    private func recursiveAddSubFolders(_ folder: BookmarkFolderData,
                                        selectedFolderGUID: String,
                                        indent: Int = 0) {
        folderStructures.append(Folder(title: title(for: folder),
                                       guid: folder.guid,
                                       indentation: indent,
                                       isSelected: folder.guid == selectedFolderGUID))
        for case let subFolder as BookmarkFolderData in folder.children ?? [] {
            let indentation = subFolder.isRoot ? 0 : indent + 1
            recursiveAddSubFolders(subFolder, selectedFolderGUID: selectedFolderGUID, indent: indentation)
        }
    }

    private func title(for folder: BookmarkFolderData) -> String {
        return LocalizedRootBookmarkFolderStrings[folder.guid] ?? folder.title
    }

    func setUpdatedTitle(_ title: String) {
        updatedTitle = title
    }

    func setUpdatedURL(_ url: String) {
        updatedUrl = url
    }

    func saveBookmark() {
        let selectedFolder = folderStructures.first {
            return $0.isSelected
        }
        guard let selectedFolder else { return }
        profile.places.updateBookmarkNode(guid: node.guid,
                                          parentGUID: selectedFolder.guid,
                                          position: node.position,
                                          title: updatedTitle,
                                          url: updatedUrl).uponQueue(.main) { [weak self] result in
            print(result)
            self?.onBookmarkSaved?()
        }
    }
}

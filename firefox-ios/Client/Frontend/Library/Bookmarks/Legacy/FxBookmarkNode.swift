// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData
import class MozillaAppServices.BookmarkSeparatorData
import enum MozillaAppServices.BookmarkNodeType

// Provides a layer of abstraction so we have more power over BookmarkNodeData provided by App Services.
// For instance, this enables us to have the LocalDesktopFolder.
protocol FxBookmarkNode: Sendable {
    var type: BookmarkNodeType { get }
    var guid: String { get }
    var parentGUID: String? { get }
    var position: UInt32 { get }
    var isRoot: Bool { get }
    var title: String { get }
}

extension FxBookmarkNode {
    var isNonEmptyFolder: Bool {
        guard let bookmarkFolder = self as? BookmarkFolderData else { return false }

        return !bookmarkFolder.childGUIDs.isEmpty
    }
}

// TODO: FXIOS-12903 Bookmark Data from Rust components is not Sendable
extension BookmarkItemData: @unchecked @retroactive Sendable, FxBookmarkNode {}

// TODO: FXIOS-12903 Bookmark Data from Rust components is not Sendable
extension BookmarkFolderData: @unchecked @retroactive Sendable, FxBookmarkNode {
    // Convenience to be able to fetch children as an array of FxBookmarkNode
    var fxChildren: [FxBookmarkNode]? {
        return self.children as? [FxBookmarkNode]
    }
}

// TODO: FXIOS-12903 Bookmark Data from Rust components is not Sendable
extension BookmarkSeparatorData: @unchecked @retroactive Sendable, FxBookmarkNode {
    var title: String { "" }
}

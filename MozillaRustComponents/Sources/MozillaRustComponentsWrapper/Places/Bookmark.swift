/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
#if canImport(MozillaRustComponents)
    import MozillaRustComponents
#endif

/// Snarfed from firefox-ios, although we don't have the fake desktop root,
/// and we only have the `All` Set.
public enum BookmarkRoots {
    public static let RootGUID = "root________"
    public static let MobileFolderGUID = "mobile______"
    public static let MenuFolderGUID = "menu________"
    public static let ToolbarFolderGUID = "toolbar_____"
    public static let UnfiledFolderGUID = "unfiled_____"

    public static let All = Set<String>([
        BookmarkRoots.RootGUID,
        BookmarkRoots.MobileFolderGUID,
        BookmarkRoots.MenuFolderGUID,
        BookmarkRoots.ToolbarFolderGUID,
        BookmarkRoots.UnfiledFolderGUID,
    ])

    public static let DesktopRoots = Set<String>([
        BookmarkRoots.MenuFolderGUID,
        BookmarkRoots.ToolbarFolderGUID,
        BookmarkRoots.UnfiledFolderGUID,
    ])
}

// Keeping `BookmarkNodeType` in the swift wrapper because the iOS code relies on the raw value of the variants of
// this enum.
public enum BookmarkNodeType: Int32 {
    // Note: these values need to match the Rust BookmarkType
    // enum in types.rs
    case bookmark = 1
    case folder = 2
    case separator = 3
    // The other node types are either queries (which we handle as
    // normal bookmarks), or have been removed from desktop, and
    // are not supported
}

/**
 * A base class containing the set of fields common to all nodes
 * in the bookmark tree.
 */
public class BookmarkNodeData {
    /**
     * The type of this bookmark.
     */
    public let type: BookmarkNodeType

    /**
     * The guid of this record. Bookmark guids are always 12 characters in the url-safe
     * base64 character set.
     */
    public let guid: String

    /**
     * Creation time, in milliseconds since the unix epoch.
     *
     * May not be a local timestamp.
     */
    public let dateAdded: Int64

    /**
     * Last modification time, in milliseconds since the unix epoch.
     */
    public let lastModified: Int64

    /**
     * The guid of this record's parent, or null if the record is the bookmark root.
     */
    public let parentGUID: String?

    /**
     * The (0-based) position of this record within it's parent.
     */
    public let position: UInt32
    // We use this from tests.
    // swiftformat:disable redundantFileprivate
    fileprivate init(type: BookmarkNodeType,
                     guid: String,
                     dateAdded: Int64,
                     lastModified: Int64,
                     parentGUID: String?,
                     position: UInt32)
    {
        self.type = type
        self.guid = guid
        self.dateAdded = dateAdded
        self.lastModified = lastModified
        self.parentGUID = parentGUID
        self.position = position
    }

    // swiftformat:enable redundantFileprivate
    /**
     * Returns true if this record is a bookmark root.
     *
     * - Note: This is determined entirely by inspecting the GUID.
     */
    public var isRoot: Bool {
        return BookmarkRoots.All.contains(guid)
    }
}

public extension BookmarkItem {
    var asBookmarkNodeData: BookmarkNodeData {
        switch self {
        case let .separator(s):
            return BookmarkSeparatorData(guid: s.guid,
                                         dateAdded: s.dateAdded,
                                         lastModified: s.lastModified,
                                         parentGUID: s.parentGuid,
                                         position: s.position)
        case let .bookmark(b):
            return BookmarkItemData(guid: b.guid,
                                    dateAdded: b.dateAdded,
                                    lastModified: b.lastModified,
                                    parentGUID: b.parentGuid,
                                    position: b.position,
                                    url: b.url,
                                    title: b.title ?? "")
        case let .folder(f):
            return BookmarkFolderData(guid: f.guid,
                                      dateAdded: f.dateAdded,
                                      lastModified: f.lastModified,
                                      parentGUID: f.parentGuid,
                                      position: f.position,
                                      title: f.title ?? "",
                                      childGUIDs: f.childGuids ?? [String](),
                                      children: f.childNodes?.map { child in child.asBookmarkNodeData })
        }
    }
}

// XXX - This function exists to convert the return types of the `bookmarksGetAllWithUrl`,
// `bookmarksSearch`, and `bookmarksGetRecent` functions which will always return the `BookmarkData`
// variant of the `BookmarkItem` enum. This function should be removed once the return types of the
// backing rust functions have been converted from `BookmarkItem`.
func toBookmarkItemDataList(items: [BookmarkItem]) -> [BookmarkItemData] {
    func asBookmarkItemData(item: BookmarkItem) -> BookmarkItemData? {
        if case let .bookmark(b) = item {
            return BookmarkItemData(guid: b.guid,
                                    dateAdded: b.dateAdded,
                                    lastModified: b.lastModified,
                                    parentGUID: b.parentGuid,
                                    position: b.position,
                                    url: b.url,
                                    title: b.title ?? "")
        }
        return nil
    }

    return items.map { asBookmarkItemData(item: $0)! }
}

/**
 * A bookmark which is a separator.
 *
 * It's type is always `BookmarkNodeType.separator`, and it has no fields
 * besides those defined by `BookmarkNodeData`.
 */
public class BookmarkSeparatorData: BookmarkNodeData {
    public init(guid: String, dateAdded: Int64, lastModified: Int64, parentGUID: String?, position: UInt32) {
        super.init(
            type: .separator,
            guid: guid,
            dateAdded: dateAdded,
            lastModified: lastModified,
            parentGUID: parentGUID,
            position: position
        )
    }
}

/**
 * A bookmark tree node that actually represents a bookmark.
 *
 * It's type is always `BookmarkNodeType.bookmark`,  and in addition to the
 * fields provided by `BookmarkNodeData`, it has a `title` and a `url`.
 */
public class BookmarkItemData: BookmarkNodeData {
    /**
     * The URL of this bookmark.
     */
    public let url: String

    /**
     * The title of the bookmark.
     *
     * Note that the bookmark storage layer treats NULL and the
     * empty string as equivalent in titles.
     */
    public let title: String

    public init(guid: String,
                dateAdded: Int64,
                lastModified: Int64,
                parentGUID: String?,
                position: UInt32,
                url: String,
                title: String)
    {
        self.url = url
        self.title = title
        super.init(
            type: .bookmark,
            guid: guid,
            dateAdded: dateAdded,
            lastModified: lastModified,
            parentGUID: parentGUID,
            position: position
        )
    }
}

/**
 * A bookmark which is a folder.
 *
 * It's type is always `BookmarkNodeType.folder`, and in addition to the
 * fields provided by `BookmarkNodeData`, it has a `title`, a list of `childGUIDs`,
 * and possibly a list of `children`.
 */
public class BookmarkFolderData: BookmarkNodeData {
    /**
     * The title of this bookmark folder.
     *
     * Note that the bookmark storage layer treats NULL and the
     * empty string as equivalent in titles.
     */
    public let title: String

    /**
     * The GUIDs of this folder's list of children.
     */
    public let childGUIDs: [String]

    /**
     * If this node was returned from the `PlacesReadConnection.getBookmarksTree` function,
     * then this should have the list of children, otherwise it will be nil.
     *
     * Note that if `recursive = false` is passed to the `getBookmarksTree` function, and
     * this is a child (or grandchild, etc) of the directly returned node, then `children`
     * will *not* be present (as that is the point of `recursive = false`).
     */
    public let children: [BookmarkNodeData]?

    public init(guid: String,
                dateAdded: Int64,
                lastModified: Int64,
                parentGUID: String?,
                position: UInt32,
                title: String,
                childGUIDs: [String],
                children: [BookmarkNodeData]?)
    {
        self.title = title
        self.childGUIDs = childGUIDs
        self.children = children
        super.init(
            type: .folder,
            guid: guid,
            dateAdded: dateAdded,
            lastModified: lastModified,
            parentGUID: parentGUID,
            position: position
        )
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Snarfed from firefox-ios, although we don't have the fake desktop root,
/// and we only have the `All` Set.
public struct BookmarkRoots {
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
}

/**
 * Enumeration of the type of a bookmark item.
 */
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
public class BookmarkNode {
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
                     position: UInt32) {
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

/**
 * A bookmark which is a separator.
 *
 * It's type is always `BookmarkNodeType.separator`, and it has no fields
 * besides those defined by `BookmarkNode`.
 */
public class BookmarkSeparator: BookmarkNode {
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
 * fields provided by `BookmarkNode`, it has a `title` and a `url`.
 */
public class BookmarkItem: BookmarkNode {
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
                title: String) {
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
 * fields provided by `BookmarkNode`, it has a `title`, a list of `childGUIDs`,
 * and possibly a list of `children`.
 */
public class BookmarkFolder: BookmarkNode {
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
    public let children: [BookmarkNode]?

    public init(guid: String,
                dateAdded: Int64,
                lastModified: Int64,
                parentGUID: String?,
                position: UInt32,
                title: String,
                childGUIDs: [String],
                children: [BookmarkNode]?) {
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

// We pass in whether or not we expect children, because we don't have a way
// of distinguishing 'empty folder' from 'this API does not return children'.
internal func unpackProtobuf(msg: MsgTypes_BookmarkNode) -> BookmarkNode {
    // Should never fail unless BookmarkNodeType in this file and
    // BookmarkType in rust get out of sync
    let type = BookmarkNodeType(rawValue: msg.nodeType)!
    let guid = msg.guid
    let parentGUID = msg.parentGuid
    let position = msg.position
    let dateAdded = msg.dateAdded
    let lastModified = msg.lastModified

    let title = msg.hasTitle ? msg.title : ""
    switch type {
    case .bookmark:
        return BookmarkItem(
            guid: guid,
            dateAdded: dateAdded,
            lastModified: lastModified,
            parentGUID: parentGUID,
            position: position,
            url: msg.url,
            title: title
        )
    case .separator:
        return BookmarkSeparator(
            guid: guid,
            dateAdded: dateAdded,
            lastModified: lastModified,
            parentGUID: parentGUID,
            position: position
        )
    case .folder:
        let childNodes = msg.childNodes.map { child in
            unpackProtobuf(msg: child)
        }
        var childGUIDs = msg.childGuids
        // We don't bother sending both the guids and the child nodes over
        // the FFI as it's redundant.
        if childGUIDs.isEmpty, !childNodes.isEmpty {
            childGUIDs = childNodes.map { node in node.guid }
        }
        let childrenExpected = msg.hasHaveChildNodes ? msg.haveChildNodes : false
        return BookmarkFolder(
            guid: guid,
            dateAdded: dateAdded,
            lastModified: lastModified,
            parentGUID: parentGUID,
            position: position,
            title: title,
            childGUIDs: childGUIDs,
            children: childrenExpected ? childNodes : nil
        )
    }
}

internal func unpackProtobufItemList(msg: MsgTypes_BookmarkNodeList) -> [BookmarkItem] {
    return msg.nodes.map { node in
        BookmarkItem(
            guid: node.guid,
            dateAdded: node.dateAdded,
            lastModified: node.lastModified,
            parentGUID: node.parentGuid,
            position: node.position,
            url: node.url,
            title: node.hasTitle ? node.title : ""
        )
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

public protocol SearchableBookmarks {
    func bookmarksByURL(url: NSURL) -> Deferred<Maybe<Cursor<BookmarkItem>>>
}

public protocol SyncableBookmarks: ResettableSyncStorage, AccountRemovalDelegate {
    // TODO
    func isUnchanged() -> Deferred<Maybe<Bool>>
}

public protocol BookmarkBufferStorage {
    func isEmpty() -> Deferred<Maybe<Bool>>
    func applyRecords(records: [BookmarkMirrorItem]) -> Success
    func doneApplyingRecordsAfterDownload() -> Success
}

public struct BookmarkRoots {
    // These match Places on desktop.
    public static let RootGUID =               "root________"
    public static let MobileFolderGUID =       "mobile______"
    public static let MenuFolderGUID =         "menu________"
    public static let ToolbarFolderGUID =      "toolbar_____"
    public static let UnfiledFolderGUID =      "unfiled_____"

    public static let FakeDesktopFolderGUID =  "desktop_____"   // Pseudo. Never mentioned in a real record.

    public static let All = Set<GUID>([
        BookmarkRoots.RootGUID,
        BookmarkRoots.MobileFolderGUID,
        BookmarkRoots.MenuFolderGUID,
        BookmarkRoots.ToolbarFolderGUID,
        BookmarkRoots.UnfiledFolderGUID,
        BookmarkRoots.FakeDesktopFolderGUID,
    ])

    /**
     * Sync records are a horrible mess of Places-native GUIDs and Sync-native IDs.
     * For example:
     * {"id":"places",
     *  "type":"folder",
     *  "title":"",
     *  "description":null,
     *  "children":["menu________","toolbar_____",
     *              "tags________","unfiled_____",
     *              "jKnyPDrBQSDg","T6XK5oJMU8ih"],
     *  "parentid":"2hYxKgBwvkEH"}"
     *
     * We thus normalize on the extended Places IDs (with underscores) for
     * local storage, and translate to the Sync IDs when creating an outbound
     * record.
     * We translate the record's ID and also its parent. Evidence suggests that
     * we don't need to translate children IDs.
     *
     * TODO: We don't create outbound records yet, so that's why there's no
     * translation in that direction yet!
     */
    public static func translateIncomingRootGUID(guid: GUID) -> GUID {
        return [
            "places": RootGUID,
            "root": RootGUID,
            "mobile": MobileFolderGUID,
            "menu": MenuFolderGUID,
            "toolbar": ToolbarFolderGUID,
            "unfiled": UnfiledFolderGUID
        ][guid] ?? guid
    }

    /*
    public static let TagsFolderGUID =         "tags________"
    public static let PinnedFolderGUID =       "pinned______"
     */

    static let RootID =    0
    static let MobileID =  1
    static let MenuID =    2
    static let ToolbarID = 3
    static let UnfiledID = 4
}

/**
 * This partly matches Places's nsINavBookmarksService, just for sanity.
 *
 * It is further extended to support the types that exist in Sync, so we can use
 * this to store mirrored rows.
 *
 * These are only used at the DB layer.
 */
public enum BookmarkNodeType: Int {
    case Bookmark = 1
    case Folder = 2
    case Separator = 3
    case DynamicContainer = 4

    case Livemark = 5
    case Query = 6

    // No microsummary: those turn into bookmarks.
}

/**
 * The immutable base interface for bookmarks and folders.
 */
public class BookmarkNode {
    public var id: Int? = nil
    public var guid: GUID
    public var title: String
    public var favicon: Favicon? = nil

    init(guid: GUID, title: String) {
        self.guid = guid
        self.title = title
    }
}

public class BookmarkSeparator: BookmarkNode {
    init(guid: GUID) {
        super.init(guid: guid, title: "—")
    }
}

/**
 * An immutable item representing a bookmark.
 *
 * To modify this, issue changes against the backing store and get an updated model.
 */
public class BookmarkItem: BookmarkNode {
    public let url: String!

    public init(guid: String, title: String, url: String) {
        self.url = url
        super.init(guid: guid, title: title)
    }
}

/**
 * A folder is an immutable abstraction over a named
 * thing that can return its child nodes by index.
 */
public class BookmarkFolder: BookmarkNode {
    public var count: Int { return 0 }
    public subscript(index: Int) -> BookmarkNode? { return nil }

    public func itemIsEditableAtIndex(index: Int) -> Bool {
        return false
    }
}

public struct BookmarkMirrorItem {
    public let guid: GUID
    public let type: BookmarkNodeType
    let serverModified: Timestamp
    let isDeleted: Bool
    let hasDupe: Bool
    let parentID: GUID?
    let parentName: String?

    // Livemarks.
    public let feedURI: String?
    public let siteURI: String?

    // Separators.
    let pos: Int?

    // Folders, livemarks, bookmarks and queries.
    let title: String?
    let description: String?

    // Bookmarks and queries.
    let bookmarkURI: String?
    let tags: String?
    let keyword: String?

    // Queries.
    let folderName: String?
    let queryID: String?

    // Folders.
    let children: [GUID]?

    // The places root is a folder but has no parentName.
    public static func folder(guid: GUID, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String?, title: String, description: String?, children: [GUID]) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .Folder, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: nil, siteURI: nil,
            pos: nil,
            title: title, description: description,
            bookmarkURI: nil, tags: nil, keyword: nil,
            folderName: nil, queryID: nil,
            children: children)
    }

    public static func livemark(guid: GUID, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String?, title: String?, description: String?, feedURI: String, siteURI: String) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .Livemark, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: feedURI, siteURI: siteURI,
            pos: nil,
            title: title, description: description,
            bookmarkURI: nil, tags: nil, keyword: nil,
            folderName: nil, queryID: nil,
            children: nil)
    }

    public static func separator(guid: GUID, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String, pos: Int) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .Separator, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: nil, siteURI: nil,
            pos: pos,
            title: nil, description: nil,
            bookmarkURI: nil, tags: nil, keyword: nil,
            folderName: nil, queryID: nil,
            children: nil)
    }

    public static func bookmark(guid: GUID, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String, title: String, description: String?, URI: String, tags: String, keyword: String?) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .Bookmark, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: nil, siteURI: nil,
            pos: nil,
            title: title, description: description,
            bookmarkURI: URI, tags: tags, keyword: keyword,
            folderName: nil, queryID: nil,
            children: nil)
    }

    public static func query(guid: GUID, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String, title: String, description: String?, URI: String, tags: String, keyword: String?, folderName: String?, queryID: String?) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)
        let parent = BookmarkRoots.translateIncomingRootGUID(parentID)

        return BookmarkMirrorItem(guid: id, type: .Query, serverModified: modified,
            isDeleted: false, hasDupe: hasDupe, parentID: parent, parentName: parentName,
            feedURI: nil, siteURI: nil,
            pos: nil,
            title: title, description: description,
            bookmarkURI: URI, tags: tags, keyword: keyword,
            folderName: folderName, queryID: queryID,
            children: nil)
    }

    public static func deleted(type: BookmarkNodeType, guid: GUID, modified: Timestamp) -> BookmarkMirrorItem {
        let id = BookmarkRoots.translateIncomingRootGUID(guid)

        return BookmarkMirrorItem(guid: id, type: type, serverModified: modified,
            isDeleted: true, hasDupe: false, parentID: nil, parentName: nil,
            feedURI: nil, siteURI: nil,
            pos: nil,
            title: nil, description: nil,
            bookmarkURI: nil, tags: nil, keyword: nil,
            folderName: nil, queryID: nil,
            children: nil)
    }
}

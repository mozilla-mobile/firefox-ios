/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import Deferred

private let log = Logger.syncLogger

public protocol SearchableBookmarks: class {
    func bookmarksByURL(url: NSURL) -> Deferred<Maybe<Cursor<BookmarkItem>>>
}

public protocol SyncableBookmarks: class, ResettableSyncStorage, AccountRemovalDelegate {
    // TODO
    func isUnchanged() -> Deferred<Maybe<Bool>>
    func getLocalDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>>
    func treesForEdges() -> Deferred<Maybe<(local: BookmarkTree, buffer: BookmarkTree)>>
    func treeForMirror() -> Deferred<Maybe<BookmarkTree>>
    func applyLocalOverrideCompletionOp(op: LocalOverrideCompletionOp, itemSources: ItemSources) -> Success
}

public enum BookmarksEditState {
    case ReadWrite
    case ReadOnly
}

public protocol EditableBookmarks: class {
    func editState() -> Deferred<Maybe<BookmarksEditState>>
}

public let NotificationBookmarkBufferValidated = "NotificationBookmarkBufferValidated"

public protocol BookmarkBufferStorage: class {
    func isEmpty() -> Deferred<Maybe<Bool>>
    func applyRecords(records: [BookmarkMirrorItem]) -> Success
    func doneApplyingRecordsAfterDownload() -> Success

    func validate() -> Success
    func getBufferedDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>>
    func applyBufferCompletionOp(op: BufferCompletionOp, itemSources: ItemSources) -> Success

    // Only use for diagnostics.
    func synchronousBufferCount() -> Int?
}

public protocol MirrorItemSource: class {
    func getMirrorItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>
    func getMirrorItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>>
    func prefetchMirrorItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success
}

public protocol BufferItemSource: class {
    func getBufferItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>
    func getBufferItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>>
    func prefetchBufferItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success
}

public protocol LocalItemSource: class {
    func getLocalItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>
    func getLocalItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>>
    func prefetchLocalItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success
}

public class ItemSources {
    public let local: LocalItemSource
    public let mirror: MirrorItemSource
    public let buffer: BufferItemSource

    public init(local: LocalItemSource, mirror: MirrorItemSource, buffer: BufferItemSource) {
        self.local = local
        self.mirror = mirror
        self.buffer = buffer
    }

    public func prefetchWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success {
        return self.local.prefetchLocalItemsWithGUIDs(guids)
         >>> { self.mirror.prefetchMirrorItemsWithGUIDs(guids) }
         >>> { self.buffer.prefetchBufferItemsWithGUIDs(guids) }
    }
}

public struct BookmarkRoots {
    // These match Places on desktop.
    public static let RootGUID =               "root________"
    public static let MobileFolderGUID =       "mobile______"
    public static let MenuFolderGUID =         "menu________"
    public static let ToolbarFolderGUID =      "toolbar_____"
    public static let UnfiledFolderGUID =      "unfiled_____"

    public static let FakeDesktopFolderGUID =  "desktop_____"   // Pseudo. Never mentioned in a real record.

    // This is the order we use.
    public static let RootChildren: [GUID] = [
        BookmarkRoots.MenuFolderGUID,
        BookmarkRoots.ToolbarFolderGUID,
        BookmarkRoots.UnfiledFolderGUID,
        BookmarkRoots.MobileFolderGUID,
    ]

    public static let DesktopRoots: [GUID] = [
        BookmarkRoots.MenuFolderGUID,
        BookmarkRoots.ToolbarFolderGUID,
        BookmarkRoots.UnfiledFolderGUID,
    ]

    public static let Real = Set<GUID>([
        BookmarkRoots.RootGUID,
        BookmarkRoots.MobileFolderGUID,
        BookmarkRoots.MenuFolderGUID,
        BookmarkRoots.ToolbarFolderGUID,
        BookmarkRoots.UnfiledFolderGUID,
    ])

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

    public static func translateOutgoingRootGUID(guid: GUID) -> GUID {
        return [
            RootGUID: "places",
            MobileFolderGUID: "mobile",
            MenuFolderGUID: "menu",
            ToolbarFolderGUID: "toolbar",
            UnfiledFolderGUID: "unfiled"
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

public func == (lhs: BookmarkMirrorItem, rhs: BookmarkMirrorItem) -> Bool {
    if lhs.type != rhs.type ||
       lhs.guid != rhs.guid ||
       lhs.serverModified != rhs.serverModified ||
       lhs.isDeleted != rhs.isDeleted ||
       lhs.hasDupe != rhs.hasDupe ||
       lhs.pos != rhs.pos ||
       lhs.faviconID != rhs.faviconID ||
       lhs.localModified != rhs.localModified ||
       lhs.parentID != rhs.parentID ||
       lhs.parentName != rhs.parentName ||
       lhs.feedURI != rhs.feedURI ||
       lhs.siteURI != rhs.siteURI ||
       lhs.title != rhs.title ||
       lhs.description != rhs.description ||
       lhs.bookmarkURI != rhs.bookmarkURI ||
       lhs.tags != rhs.tags ||
       lhs.keyword != rhs.keyword ||
       lhs.folderName != rhs.folderName ||
       lhs.queryID != rhs.queryID {
        return false
    }

    if let lhsChildren = lhs.children, rhsChildren = rhs.children {
        return lhsChildren == rhsChildren
    }
    return lhs.children == nil && rhs.children == nil
}

public struct BookmarkMirrorItem: Equatable {
    public let guid: GUID
    public let type: BookmarkNodeType
    public var serverModified: Timestamp
    public let isDeleted: Bool
    public let hasDupe: Bool
    public let parentID: GUID?
    public let parentName: String?

    // Livemarks.
    public let feedURI: String?
    public let siteURI: String?

    // Separators.
    let pos: Int?

    // Folders, livemarks, bookmarks and queries.
    public let title: String?
    let description: String?

    // Bookmarks and queries.
    let bookmarkURI: String?
    let tags: String?
    let keyword: String?

    // Queries.
    let folderName: String?
    let queryID: String?

    // Folders.
    public let children: [GUID]?

    // Internal stuff.
    let faviconID: Int?
    public let localModified: Timestamp?
    let syncStatus: SyncStatus?

    public func copyWithParentID(parentID: GUID, parentName: String?) -> BookmarkMirrorItem {
        return BookmarkMirrorItem(
            guid: self.guid,
            type: self.type,
            serverModified: self.serverModified,
            isDeleted: self.isDeleted,
            hasDupe: self.hasDupe,
            parentID: parentID,
            parentName: parentName,
            feedURI: self.feedURI,
            siteURI: self.siteURI,
            pos: self.pos,
            title: self.title,
            description: self.description,
            bookmarkURI: self.bookmarkURI,
            tags: self.tags,
            keyword: self.keyword,
            folderName: self.folderName,
            queryID: self.queryID,
            children: self.children,
            faviconID: self.faviconID,
            localModified: self.localModified,
            syncStatus: self.syncStatus)
    }

    // Ignores internal metadata and GUID; a pure value comparison.
    // Does compare child GUIDs!
    public func sameAs(rhs: BookmarkMirrorItem) -> Bool {
        if self.type != rhs.type ||
           self.isDeleted != rhs.isDeleted ||
           self.pos != rhs.pos ||
           self.parentID != rhs.parentID ||
           self.parentName != rhs.parentName ||
           self.feedURI != rhs.feedURI ||
           self.siteURI != rhs.siteURI ||
           self.title != rhs.title ||
           (self.description ?? "") != (rhs.description ?? "") ||
           self.bookmarkURI != rhs.bookmarkURI ||
           self.tags != rhs.tags ||
           self.keyword != rhs.keyword ||
           self.folderName != rhs.folderName ||
           self.queryID != rhs.queryID {
            return false
        }

        if let lhsChildren = self.children, rhsChildren = rhs.children {
            return lhsChildren == rhsChildren
        }
        return self.children == nil && rhs.children == nil
    }

    public func asJSON() -> JSON {
        return self.asJSONWithChildren(self.children)
    }

    public func asJSONWithChildren(children: [GUID]?) -> JSON {
        var out: [String: AnyObject] = [:]

        out["id"] = BookmarkRoots.translateOutgoingRootGUID(self.guid)

        func take(key: String, _ val: String?) {
            guard let val = val else {
                return
            }
            out[key] = val
        }

        if self.isDeleted {
            out["deleted"] = true
            return JSON(out)
        }

        out["hasDupe"] = self.hasDupe

        // TODO: this should never be nil!
        if let parentID = self.parentID {
            out["parentid"] = BookmarkRoots.translateOutgoingRootGUID(parentID)
            take("parentName", titleForSpecialGUID(parentID) ?? self.parentName)
        }

        func takeBookmarkFields() {
            take("title", self.title)
            take("bmkUri", self.bookmarkURI)
            take("description", self.description)
            if let tags = self.tags {
                let tagsJSON = JSON.parse(tags)
                if let tagsArray = tagsJSON.asArray where tagsArray.every({ $0.isString }) {
                    out["tags"] = tagsArray
                } else {
                    out["tags"] = []
                }
            } else {
                out["tags"] = []
            }
            take("keyword", self.keyword)
        }

        func takeFolderFields() {
            take("title", titleForSpecialGUID(self.guid) ?? self.title)
            take("description", self.description)
            if let children = children {
                if BookmarkRoots.RootGUID == self.guid {
                    // Only the root contains roots, and so only its children
                    // need to be translated.
                    out["children"] = children.map(BookmarkRoots.translateOutgoingRootGUID)
                } else {
                    out["children"] = children
                }
            }
        }

        switch self.type {

        case .Query:
            out["type"] = "query"
            take("folderName", self.folderName)
            take("queryId", self.queryID)
            takeBookmarkFields()

        case .Bookmark:
            out["type"] = "bookmark"
            takeBookmarkFields()

        case .Livemark:
            out["type"] = "livemark"
            take("siteUri", self.siteURI)
            take("feedUri", self.feedURI)
            takeFolderFields()

        case .Folder:
            out["type"] = "folder"
            takeFolderFields()

        case .Separator:
            out["type"] = "separator"
            if let pos = self.pos {
                out["pos"] = pos
            }

        case .DynamicContainer:
            // Sigh.
            preconditionFailure("DynamicContainer not supported.")
        }

        return JSON(out)
    }

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
            children: children,
            faviconID: nil, localModified: nil, syncStatus: nil)
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
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
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
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
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
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
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
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
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
            children: nil,
            faviconID: nil, localModified: nil, syncStatus: nil)
    }
}

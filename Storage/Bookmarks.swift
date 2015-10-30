/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

// A small structure to encapsulate all the possible data that we can get
// from an application sharing a web page or a URL.
public struct ShareItem {
    public let url: String
    public let title: String?
    public let favicon: Favicon?

    public init(url: String, title: String?, favicon: Favicon?) {
        self.url = url
        self.title = title
        self.favicon = favicon
    }
}

public protocol ShareToDestination {
    func shareItem(item: ShareItem)
}

public protocol SearchableBookmarks {
    func bookmarksByURL(url: NSURL) -> Deferred<Maybe<Cursor<BookmarkItem>>>
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

    public static func livemark(guid: GUID, modified: Timestamp, hasDupe: Bool, parentID: GUID, parentName: String, title: String, description: String?, feedURI: String, siteURI: String) -> BookmarkMirrorItem {
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

public protocol BookmarkMirrorStorage {
    func applyRecords(records: [BookmarkMirrorItem]) -> Success
}


public struct BookmarkRoots {
    // These match Places on desktop.
    public static let RootGUID =               "root________"
    public static let MobileFolderGUID =       "mobile______"
    public static let MenuFolderGUID =         "menu________"
    public static let ToolbarFolderGUID =      "toolbar_____"
    public static let UnfiledFolderGUID =      "unfiled_____"

    public static let FakeDesktopFolderGUID =  "desktop_____"   // Pseudo. Never mentioned in a real record.

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
    public var guid: String
    public var title: String
    public var favicon: Favicon? = nil

    init(guid: String, title: String) {
        self.guid = guid
        self.title = title
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

/**
 * A model is a snapshot of the bookmarks store, suitable for backing a table view.
 *
 * Navigation through the folder hierarchy produces a sequence of models.
 *
 * Changes to the backing store implicitly invalidates a subset of models.
 *
 * 'Refresh' means requesting a new model from the store.
 */
public class BookmarksModel {
    let modelFactory: BookmarksModelFactory
    public let current: BookmarkFolder

    public init(modelFactory: BookmarksModelFactory, root: BookmarkFolder) {
        self.modelFactory = modelFactory
        self.current = root
    }

    /**
     * Produce a new model rooted at the appropriate folder. Fails if the folder doesn't exist.
     */
    public func selectFolder(folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return modelFactory.modelForFolder(folder)
    }

    /**
     * Produce a new model rooted at the appropriate folder. Fails if the folder doesn't exist.
     */
    public func selectFolder(guid: String) -> Deferred<Maybe<BookmarksModel>> {
        return modelFactory.modelForFolder(guid)
    }

    /**
     * Produce a new model rooted at the base of the hierarchy. Should never fail.
     */
    public func selectRoot() -> Deferred<Maybe<BookmarksModel>> {
        return modelFactory.modelForRoot()
    }

    /**
     * Produce a new model rooted at the same place as this model. Can fail if
     * the folder has been deleted from the backing store.
     */
    public func reloadData() -> Deferred<Maybe<BookmarksModel>> {
        return modelFactory.modelForFolder(current)
    }
}

public protocol BookmarksModelFactory {
    func modelForFolder(folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>>
    func modelForFolder(guid: GUID) -> Deferred<Maybe<BookmarksModel>>
    func modelForFolder(guid: GUID, title: String) -> Deferred<Maybe<BookmarksModel>>

    func modelForRoot() -> Deferred<Maybe<BookmarksModel>>

    // Whenever async construction is necessary, we fall into a pattern of needing
    // a placeholder that behaves correctly for the period between kickoff and set.
    var nullModel: BookmarksModel { get }

    func isBookmarked(url: String) -> Deferred<Maybe<Bool>>
    func remove(bookmark: BookmarkNode) -> Success
    func removeByURL(url: String) -> Success
    func clearBookmarks() -> Success
}

/*
 * A folder that contains an array of children.
 */
public class MemoryBookmarkFolder: BookmarkFolder, SequenceType {
    let children: [BookmarkNode]

    public init(guid: GUID, title: String, children: [BookmarkNode]) {
        self.children = children
        super.init(guid: guid, title: title)
    }

    public struct BookmarkNodeGenerator: GeneratorType {
        public typealias Element = BookmarkNode
        let children: [BookmarkNode]
        var index: Int = 0

        init(children: [BookmarkNode]) {
            self.children = children
        }

        public mutating func next() -> BookmarkNode? {
            return index < children.count ? children[index++] : nil
        }
    }

    override public var favicon: Favicon? {
        get {
            if let path = NSBundle.mainBundle().pathForResource("bookmarkFolder", ofType: "png") {
                let url = NSURL(fileURLWithPath: path)
                return Favicon(url: url.absoluteString, date: NSDate(), type: IconType.Local)
            }
            return nil
        }
        set {
        }
    }

    override public var count: Int {
        return children.count
    }

    override public subscript(index: Int) -> BookmarkNode {
        get {
            return children[index]
        }
    }

    override public func itemIsEditableAtIndex(index: Int) -> Bool {
        return true
    }

    public func generate() -> BookmarkNodeGenerator {
        return BookmarkNodeGenerator(children: self.children)
    }

    /**
     * Return a new immutable folder that's just like this one,
     * but also contains the new items.
     */
    func append(items: [BookmarkNode]) -> MemoryBookmarkFolder {
        if (items.isEmpty) {
            return self
        }
        return MemoryBookmarkFolder(guid: self.guid, title: self.title, children: self.children + items)
    }
}

public class MemoryBookmarksSink: ShareToDestination {
    var queue: [BookmarkNode] = []
    public init() { }
    public func shareItem(item: ShareItem) {
        let title = item.title == nil ? "Untitled" : item.title!
        func exists(e: BookmarkNode) -> Bool {
            if let bookmark = e as? BookmarkItem {
                return bookmark.url == item.url;
            }

            return false;
        }

        // Don't create duplicates.
        if (!queue.contains(exists)) {
            queue.append(BookmarkItem(guid: Bytes.generateGUID(), title: title, url: item.url))
        }
    }
}


private extension SuggestedSite {
    func asBookmark() -> BookmarkNode {
        let b = BookmarkItem(guid: self.guid ?? Bytes.generateGUID(), title: self.title, url: self.url)
        b.favicon = self.icon
        return b
    }
}

public class PrependedBookmarkFolder: BookmarkFolder {
    private let main: BookmarkFolder
    private let prepend: BookmarkNode

    init(main: BookmarkFolder, prepend: BookmarkNode) {
        self.main = main
        self.prepend = prepend
        super.init(guid: main.guid, title: main.guid)
    }

    override public var count: Int {
        return self.main.count + 1
    }

    override public subscript(index: Int) -> BookmarkNode? {
        if index == 0 {
            return self.prepend
        }

        return self.main[index - 1]
    }

    override public func itemIsEditableAtIndex(index: Int) -> Bool {
        return index > 0 && self.main.itemIsEditableAtIndex(index - 1)
    }
}

public class BookmarkFolderWithDefaults: BookmarkFolder {
    private let folder: BookmarkFolder
    private let sites: SuggestedSitesCursor

    init(folder: BookmarkFolder, sites: SuggestedSitesCursor) {
        self.folder = folder
        self.sites = sites
        super.init(guid: folder.guid, title: folder.title)
    }

    override public var count: Int {
        return self.folder.count + self.sites.count
    }

    override public subscript(index: Int) -> BookmarkNode? {
        if index < self.folder.count {
            return self.folder[index]
        }

        if let site = self.sites[index - self.folder.count] {
            return site.asBookmark()
        }

        return nil
    }

    override public func itemIsEditableAtIndex(index: Int) -> Bool {
        return index < self.folder.count
    }
}

/**
 * A trivial offline model factory that represents a simple hierarchy.
 */
public class MockMemoryBookmarksStore: BookmarksModelFactory, ShareToDestination {
    let mobile: MemoryBookmarkFolder
    let root: MemoryBookmarkFolder
    var unsorted: MemoryBookmarkFolder

    let sink: MemoryBookmarksSink

    public init() {
        let res = [BookmarkItem]()

        mobile = MemoryBookmarkFolder(guid: BookmarkRoots.MobileFolderGUID, title: "Mobile Bookmarks", children: res)

        unsorted = MemoryBookmarkFolder(guid: BookmarkRoots.UnfiledFolderGUID, title: "Unsorted Bookmarks", children: [])
        sink = MemoryBookmarksSink()

        root = MemoryBookmarkFolder(guid: BookmarkRoots.RootGUID, title: "Root", children: [mobile, unsorted])
    }

    public func modelForFolder(folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(folder.guid, title: folder.title)
    }

    public func modelForFolder(guid: GUID) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(guid, title: "")
    }

    public func modelForFolder(guid: GUID, title: String) -> Deferred<Maybe<BookmarksModel>> {
        var m: BookmarkFolder
        switch (guid) {
        case BookmarkRoots.MobileFolderGUID:
            // Transparently merges in any queued items.
            m = self.mobile.append(self.sink.queue)
            break;
        case BookmarkRoots.RootGUID:
            m = self.root
            break;
        case BookmarkRoots.UnfiledFolderGUID:
            m = self.unsorted
            break;
        default:
            return deferMaybe(DatabaseError(description: "No such folder \(guid)."))
        }

        return deferMaybe(BookmarksModel(modelFactory: self, root: m))
    }

    public func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        return deferMaybe(BookmarksModel(modelFactory: self, root: self.root))
    }

    /**
    * This class could return the full data immediately. We don't, because real DB-backed code won't.
    */
    public var nullModel: BookmarksModel {
        let f = MemoryBookmarkFolder(guid: BookmarkRoots.RootGUID, title: "Root", children: [])
        return BookmarksModel(modelFactory: self, root: f)
    }

    public func shareItem(item: ShareItem) {
        self.sink.shareItem(item)
    }

    public func isBookmarked(url: String) -> Deferred<Maybe<Bool>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    public func remove(bookmark: BookmarkNode) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    public func removeByURL(url: String) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    public func clearBookmarks() -> Success {
        return succeed()
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared

/**
 * The kinda-immutable base interface for bookmarks and folders.
 */
public class BookmarkNode {
    public var id: Int? = nil
    public let guid: GUID
    public let title: String
    public let isEditable: Bool
    public var favicon: Favicon? = nil

    init(guid: GUID, title: String, isEditable: Bool=false) {
        self.guid = guid
        self.title = title
        self.isEditable = isEditable
    }

    public var canDelete: Bool {
        return self.isEditable
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

    public init(guid: String, title: String, url: String, isEditable: Bool=false) {
        self.url = url
        super.init(guid: guid, title: title, isEditable: isEditable)
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
        return self[index]?.canDelete ?? false
    }

    override public var canDelete: Bool {
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
public class BookmarksModel: BookmarksModelFactorySource {
    public let modelFactory: BookmarksModelFactory
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

    public var canDelete: Bool {
        return false
    }
}

public protocol BookmarksModelFactorySource {
    var modelFactory: BookmarksModelFactory { get }
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
    func removeByGUID(guid: GUID) -> Success
    func removeByURL(url: String) -> Success
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

    public func removeByGUID(guid: GUID) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    public func removeByURL(url: String) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    public func clearBookmarks() -> Success {
        return succeed()
    }
}

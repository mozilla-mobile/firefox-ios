/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared

private let log = Logger.syncLogger

/**
 * The kinda-immutable base interface for bookmarks and folders.
 */
open class BookmarkNode {
    open var id: Int?
    open let guid: GUID
    open let title: String
    open let isEditable: Bool
    open var favicon: Favicon?

    init(guid: GUID, title: String, isEditable: Bool=false) {
        self.guid = guid
        self.title = title
        self.isEditable = isEditable
    }

    open var canDelete: Bool {
        return self.isEditable
    }
}

open class BookmarkSeparator: BookmarkNode {
    init(guid: GUID) {
        super.init(guid: guid, title: "—")
    }
}

/**
 * An immutable item representing a bookmark.
 *
 * To modify this, issue changes against the backing store and get an updated model.
 */
open class BookmarkItem: BookmarkNode {
    open let url: String!

    public init(guid: String, title: String, url: String, isEditable: Bool=false) {
        self.url = url
        super.init(guid: guid, title: title, isEditable: isEditable)
    }
}

/**
 * A folder is an immutable abstraction over a named
 * thing that can return its child nodes by index.
 */
open class BookmarkFolder: BookmarkNode {
    open var count: Int { return 0 }
    open subscript(index: Int) -> BookmarkNode? { return nil }

    open func itemIsEditableAtIndex(_ index: Int) -> Bool {
        return self[index]?.canDelete ?? false
    }

    override open var canDelete: Bool {
        return false
    }

    open func removeItemWithGUID(_ guid: GUID) -> BookmarkFolder? {
        return nil
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
open class BookmarksModel: BookmarksModelFactorySource {
    fileprivate let factory: BookmarksModelFactory
    open let modelFactory: Deferred<Maybe<BookmarksModelFactory>>
    open let current: BookmarkFolder

    public init(modelFactory: BookmarksModelFactory, root: BookmarkFolder) {
        self.factory = modelFactory
        self.modelFactory = deferMaybe(modelFactory)
        self.current = root
    }

    /**
     * Produce a new model rooted at the appropriate folder. Fails if the folder doesn't exist.
     */
    open func selectFolder(_ folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.factory.modelForFolder(folder)
    }

    /**
     * Produce a new model rooted at the appropriate folder. Fails if the folder doesn't exist.
     */
    open func selectFolder(_ guid: String) -> Deferred<Maybe<BookmarksModel>> {
        return self.factory.modelForFolder(guid)
    }

    /**
     * Produce a new model rooted at the base of the hierarchy. Should never fail.
     */
    open func selectRoot() -> Deferred<Maybe<BookmarksModel>> {
        return self.factory.modelForRoot()
    }

    /**
     * Produce a new model with a memory-backed root with the given GUID removed from the current folder
     */
    open func removeGUIDFromCurrent(_ guid: GUID) -> BookmarksModel {
        if let removedRoot = self.current.removeItemWithGUID(guid) {
            return BookmarksModel(modelFactory: self.factory, root: removedRoot)
        }
        log.warning("BookmarksModel.removeGUIDFromCurrent did not remove anything. Check to make sure you're not using the abstract BookmarkFolder class.")
        return self
    }

    /**
     * Produce a new model rooted at the same place as this model. Can fail if
     * the folder has been deleted from the backing store.
     */
    open func reloadData() -> Deferred<Maybe<BookmarksModel>> {
        return self.factory.modelForFolder(current)
    }

    open var canDelete: Bool {
        return false
    }
}

public protocol BookmarksModelFactorySource {
    var modelFactory: Deferred<Maybe<BookmarksModelFactory>> { get }
}

public protocol BookmarksModelFactory {
    func modelForFolder(_ folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>>
    func modelForFolder(_ guid: GUID) -> Deferred<Maybe<BookmarksModel>>
    func modelForFolder(_ guid: GUID, title: String) -> Deferred<Maybe<BookmarksModel>>

    func modelForRoot() -> Deferred<Maybe<BookmarksModel>>

    // Whenever async construction is necessary, we fall into a pattern of needing
    // a placeholder that behaves correctly for the period between kickoff and set.
    var nullModel: BookmarksModel { get }

    func isBookmarked(_ url: String) -> Deferred<Maybe<Bool>>
    func removeByGUID(_ guid: GUID) -> Success
    @discardableResult func removeByURL(_ url: String) -> Success
}

/*
 * A folder that contains an array of children.
 */
open class MemoryBookmarkFolder: BookmarkFolder, Sequence {
    let children: [BookmarkNode]

    public init(guid: GUID, title: String, children: [BookmarkNode]) {
        self.children = children
        super.init(guid: guid, title: title)
    }

    public struct BookmarkNodeGenerator: IteratorProtocol {
        public typealias Element = BookmarkNode
        let children: [BookmarkNode]
        var index: Int = 0

        init(children: [BookmarkNode]) {
            self.children = children
        }

        public mutating func next() -> BookmarkNode? {
            if index < children.count {
                defer { index += 1 }
                return children[index]
            }
            return nil
        }
    }

    override open var favicon: Favicon? {
        get {
            if let path = Bundle.main.path(forResource: "bookmarkFolder", ofType: "png") {
                let url = URL(fileURLWithPath: path)
                return Favicon(url: url.absoluteString, date: Date(), type: IconType.local)
            }
            return nil
        }
        set {
        }
    }

    override open var count: Int {
        return children.count
    }

    override open subscript(index: Int) -> BookmarkNode {
        get {
            return children[index]
        }
    }

    override open func itemIsEditableAtIndex(_ index: Int) -> Bool {
        return true
    }

    override open func removeItemWithGUID(_ guid: GUID) -> BookmarkFolder? {
        let without = children.filter { $0.guid != guid }
        return MemoryBookmarkFolder(guid: self.guid, title: self.title, children: without)
    }

    open func makeIterator() -> BookmarkNodeGenerator {
        return BookmarkNodeGenerator(children: self.children)
    }

    /**
     * Return a new immutable folder that's just like this one,
     * but also contains the new items.
     */
    func append(_ items: [BookmarkNode]) -> MemoryBookmarkFolder {
        if items.isEmpty {
            return self
        }
        return MemoryBookmarkFolder(guid: self.guid, title: self.title, children: self.children + items)
    }
}

open class MemoryBookmarksSink: ShareToDestination {
    var queue: [BookmarkNode] = []
    public init() { }
    open func shareItem(_ item: ShareItem) -> Success {
        let title = item.title == nil ? "Untitled" : item.title!
        func exists(_ e: BookmarkNode) -> Bool {
            if let bookmark = e as? BookmarkItem {
                return bookmark.url == item.url
            }

            return false
        }

        // Don't create duplicates.
        if !queue.contains(where: exists) {
            queue.append(BookmarkItem(guid: Bytes.generateGUID(), title: title, url: item.url))
        }

        return succeed()
    }
}

private extension SuggestedSite {
    func asBookmark() -> BookmarkNode {
        let b = BookmarkItem(guid: self.guid ?? Bytes.generateGUID(), title: self.title, url: self.url)
        b.favicon = self.icon
        return b
    }
}

open class PrependedBookmarkFolder: BookmarkFolder {
    fileprivate let main: BookmarkFolder
    fileprivate let prepend: BookmarkNode

    init(main: BookmarkFolder, prepend: BookmarkNode) {
        self.main = main
        self.prepend = prepend
        super.init(guid: main.guid, title: main.guid)
    }

    override open var count: Int {
        return self.main.count + 1
    }

    override open subscript(index: Int) -> BookmarkNode? {
        if index == 0 {
            return self.prepend
        }

        return self.main[index - 1]
    }

    override open func itemIsEditableAtIndex(_ index: Int) -> Bool {
        return index > 0 && self.main.itemIsEditableAtIndex(index - 1)
    }

    override open func removeItemWithGUID(_ guid: GUID) -> BookmarkFolder? {
        guard let removedFolder = main.removeItemWithGUID(guid) else {
            log.warning("Failed to remove child item from prepended folder. Check that main folder overrides removeItemWithGUID.")
            return nil
        }
        return PrependedBookmarkFolder(main: removedFolder, prepend: prepend)
    }
}

/**
 * A trivial offline model factory that represents a simple hierarchy.
 */
open class MockMemoryBookmarksStore: BookmarksModelFactory, ShareToDestination {
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

    open func modelForFolder(_ folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(folder.guid, title: folder.title)
    }

    open func modelForFolder(_ guid: GUID) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(guid, title: "")
    }

    open func modelForFolder(_ guid: GUID, title: String) -> Deferred<Maybe<BookmarksModel>> {
        var m: BookmarkFolder
        switch guid {
        case BookmarkRoots.MobileFolderGUID:
            // Transparently merges in any queued items.
            m = self.mobile.append(self.sink.queue)
            break
        case BookmarkRoots.RootGUID:
            m = self.root
            break
        case BookmarkRoots.UnfiledFolderGUID:
            m = self.unsorted
            break
        default:
            return deferMaybe(DatabaseError(description: "No such folder \(guid)."))
        }

        return deferMaybe(BookmarksModel(modelFactory: self, root: m))
    }

    open func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        return deferMaybe(BookmarksModel(modelFactory: self, root: self.root))
    }

    /**
    * This class could return the full data immediately. We don't, because real DB-backed code won't.
    */
    open var nullModel: BookmarksModel {
        let f = MemoryBookmarkFolder(guid: BookmarkRoots.RootGUID, title: "Root", children: [])
        return BookmarksModel(modelFactory: self, root: f)
    }

    open func shareItem(_ item: ShareItem) -> Success {
        return self.sink.shareItem(item)
    }

    open func isBookmarked(_ url: String) -> Deferred<Maybe<Bool>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    open func removeByGUID(_ guid: GUID) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    open func removeByURL(_ url: String) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    open func clearBookmarks() -> Success {
        return succeed()
    }
}

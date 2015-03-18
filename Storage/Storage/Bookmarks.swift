/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public struct ShareItem {
    public let url: String
    public let title: String?

    public init(url: String, title: String?) {
        self.url = url
        self.title = title
    }
}

public protocol ShareToDestination {
    func shareItem(item: ShareItem)
}

public struct BookmarkRoots {
    // These are stolen from Fennec's BrowserContract.
    static let MOBILE_FOLDER_GUID = "mobile"
    static let PLACES_FOLDER_GUID = "places"
    static let MENU_FOLDER_GUID = "menu"
    static let TAGS_FOLDER_GUID = "tags"
    static let TOOLBAR_FOLDER_GUID = "toolbar"
    static let UNFILED_FOLDER_GUID = "unfiled"
    static let FAKE_DESKTOP_FOLDER_GUID = "desktop"
    static let PINNED_FOLDER_GUID = "pinned"
}

/**
 * The immutable base interface for bookmarks and folders.
 */
@objc public protocol BookmarkNode {
    var guid: String { get }
    var title: String { get }
    var icon: UIImage { get }
}

@objc public protocol Bookmark : BookmarkNode {
    var url: String! { get }
}

/**
 * An immutable item representing a bookmark.
 *
 * To modify this, issue changes against the backing store and get an updated model.
 */
public class BookmarkItem: Bookmark {
    public let guid: String
    public let url: String!
    public let title: String

    var _icon: UIImage?
    public var icon: UIImage {
        if (self._icon != nil) {
            return self._icon!
        }
        return UIImage(named: "defaultFavicon")!
    }

    public init(guid: String, title: String, url: String) {
        self.guid = guid
        self.title = title
        self.url = url
    }
}

/**
 * A folder is an immutable abstraction over a named
 * thing that can return its child nodes by index.
 */
@objc public protocol BookmarkFolder: BookmarkNode {
    var count: Int { get }
    subscript(index: Int) -> BookmarkNode { get }
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
    public func selectFolder(folder: BookmarkFolder, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        modelFactory.modelForFolder(folder, success: success, failure: failure)
    }

    /**
     * Produce a new model rooted at the appropriate folder. Fails if the folder doesn't exist.
     */
    public func selectFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        modelFactory.modelForFolder(guid, success: success, failure: failure)
    }

    /**
     * Produce a new model rooted at the base of the hierarchy. Should never fail.
     */
    public func selectRoot(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        modelFactory.modelForRoot(success, failure: failure)
    }

    /**
     * Produce a new model rooted at the same place as this model. Can fail if
     * the folder has been deleted from the backing store.
     */
    public func reloadData(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        modelFactory.modelForFolder(current, success: success, failure: failure)
    }
}

public protocol BookmarksModelFactory {
    func modelForFolder(folder: BookmarkFolder, success: (BookmarksModel) -> (), failure: (Any) -> ())
    func modelForFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ())

    func modelForRoot(success: (BookmarksModel) -> (), failure: (Any) -> ())

    // Whenever async construction is necessary, we fall into a pattern of needing
    // a placeholder that behaves correctly for the period between kickoff and set.
    var nullModel: BookmarksModel { get }

    func isBookmarked(url: String, success: (Bool) -> (), failure: (Any) -> ())
    func remove(bookmark: BookmarkNode, success: (Bool) -> (), failure: (Any) -> ())
}

/*
 * A folder that contains an array of children.
 */
public class MemoryBookmarkFolder: BookmarkFolder, SequenceType {
    public let guid: String
    public let title: String
    let children: [BookmarkNode]

    public init(guid: String, title: String, children: [BookmarkNode]) {
        self.guid = guid
        self.title = title
        self.children = children
    }

    public struct BookmarkNodeGenerator: GeneratorType {
        typealias Element = BookmarkNode
        let children: [BookmarkNode]
        var index: Int = 0

        init(children: [BookmarkNode]) {
            self.children = children
        }

        public mutating func next() -> BookmarkNode? {
            return index < children.count ? children[index++] : nil
        }
    }

    public var icon: UIImage {
        return UIImage(named: "bookmark_folder_closed")!
    }

    public var count: Int {
        return children.count
    }

    public subscript(index: Int) -> BookmarkNode {
        get {
            return children[index]
        }
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
        if (!contains(queue, exists)) {
            queue.append(BookmarkItem(guid: NSUUID().UUIDString, title: title, url: item.url))
        }
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
        var res = [BookmarkItem]()
        for i in 0...10 {
            res.append(BookmarkItem(guid: Bytes.generateGUID(), title: "Title \(i)", url: "http://www.example.com/\(i)"))
        }

        mobile = MemoryBookmarkFolder(guid: BookmarkRoots.MOBILE_FOLDER_GUID, title: "Mobile Bookmarks", children: res)

        unsorted = MemoryBookmarkFolder(guid: BookmarkRoots.UNFILED_FOLDER_GUID, title: "Unsorted Bookmarks", children: [])
        sink = MemoryBookmarksSink()

        root = MemoryBookmarkFolder(guid: BookmarkRoots.PLACES_FOLDER_GUID, title: "Root", children: [mobile, unsorted])
    }

    public func modelForFolder(folder: BookmarkFolder, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        self.modelForFolder(folder.guid, success, failure)
    }

    public  func modelForFolder(guid: String, success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        var m: BookmarkFolder
        switch (guid) {
        case BookmarkRoots.MOBILE_FOLDER_GUID:
            // Transparently merges in any queued items.
            m = self.mobile.append(self.sink.queue)
            break;
        case BookmarkRoots.PLACES_FOLDER_GUID:
            m = self.root
            break;
        case BookmarkRoots.UNFILED_FOLDER_GUID:
            m = self.unsorted
            break;
        default:
            failure("No such folder.")
            return
        }

        success(BookmarksModel(modelFactory: self, root: m))
    }

    public func modelForRoot(success: (BookmarksModel) -> (), failure: (Any) -> ()) {
        success(BookmarksModel(modelFactory: self, root: self.root))
    }

    /**
    * This class could return the full data immediately. We don't, because real DB-backed code won't.
    */
    public var nullModel: BookmarksModel {
        let f = MemoryBookmarkFolder(guid: BookmarkRoots.PLACES_FOLDER_GUID, title: "Root", children: [])
        return BookmarksModel(modelFactory: self, root: f)
    }

    public func shareItem(item: ShareItem) {
        self.sink.shareItem(item)
    }

    public func isBookmarked(url: String, success: (Bool) -> (), failure: (Any) -> ()) {
        failure("Not implemented")
    }

    public func remove(bookmark: BookmarkNode, success: (Bool) -> (), failure: (Any) -> ()) {
        failure("Not implemented")
    }
}
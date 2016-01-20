/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

private let log = Logger.syncLogger

public protocol SearchableBookmarks {
    func bookmarksByURL(url: NSURL) -> Deferred<Maybe<Cursor<BookmarkItem>>>
}

public protocol SyncableBookmarks: ResettableSyncStorage, AccountRemovalDelegate {
    // TODO
    func isUnchanged() -> Deferred<Maybe<Bool>>
    func getLocalDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>>
    func treesForEdges() -> Deferred<Maybe<(local: BookmarkTree, buffer: BookmarkTree)>>
    func treeForMirror() -> Deferred<Maybe<BookmarkTree>>
    func applyLocalOverrideCompletionOp(op: LocalOverrideCompletionOp, withModifiedTimestamp timestamp: Timestamp) -> Success
}

public protocol BookmarkBufferStorage {
    func isEmpty() -> Deferred<Maybe<Bool>>
    func applyRecords(records: [BookmarkMirrorItem]) -> Success
    func doneApplyingRecordsAfterDownload() -> Success

    func validate() -> Success
    func getBufferedDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>>
    func applyBufferCompletionOp(op: BufferCompletionOp) -> Success

    func getBufferItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>
    func getBufferItemsWithGUIDs(guids: [GUID]) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>>
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

    // Internal stuff.
    let faviconID: Int?
    let localModified: Timestamp?
    let syncStatus: SyncStatus?

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

// MARK: - Defining a tree structure for syncability.

public enum BookmarkTreeNode: Equatable {
    indirect case Folder(guid: GUID, children: [BookmarkTreeNode])
    case NonFolder(guid: GUID)
    case Unknown(guid: GUID)

    // Because shared associated values between enum cases aren't possible.
    public var recordGUID: GUID {
        switch self {
        case let .Folder(guid, _):
            return guid
        case let .NonFolder(guid):
            return guid
        case let .Unknown(guid):
            return guid
        }
    }

    public var isRoot: Bool {
        return BookmarkRoots.All.contains(self.recordGUID)
    }

    public func hasChildList(nodes: [BookmarkTreeNode]) -> Bool {
        if case let .Folder(_, ours) = self {
            return ours.elementsEqual(nodes, isEquivalent: { $0.recordGUID == $1.recordGUID })
        }
        return false
    }

    public func hasSameChildListAs(other: BookmarkTreeNode) -> Bool {
        if case let .Folder(_, ours) = self {
            if case let .Folder(_, theirs) = other {
                return ours.elementsEqual(theirs, isEquivalent: { $0.recordGUID == $1.recordGUID })
            }
        }
        return false
    }
}

public func == (lhs: BookmarkTreeNode, rhs: BookmarkTreeNode) -> Bool {
    switch lhs {
    case let .Folder(guid, children):
        if case let .Folder(rguid, rchildren) = rhs {
            return guid == rguid && children == rchildren
        }
        return false
    case let .NonFolder(guid):
        if case let .NonFolder(rguid) = rhs {
            return guid == rguid
        }
        return false
    case let .Unknown(guid):
        if case let .Unknown(rguid) = rhs {
            return guid == rguid
        }
        return false
    }
}

typealias StructureRow = (parent: GUID, child: GUID, type: BookmarkNodeType?)

public struct BookmarkTree {
    // Records with no parents.
    public let subtrees: [BookmarkTreeNode]

    // Record GUID -> record.
    public let lookup: [GUID: BookmarkTreeNode]

    // Child GUID -> parent GUID.
    public let parents: [GUID: GUID]

    // Records that appear in 'lookup' because they're modified, but aren't present
    // in 'subtrees' because their parent didn't change.
    public let orphans: Set<GUID>

    // Records that have been deleted.
    public let deleted: Set<GUID>

    // Accessor for all top-level folders' GUIDs.
    public var subtreeGUIDs: Set<GUID> {
        return Set(self.subtrees.map { $0.recordGUID })
    }

    public var isEmpty: Bool {
        return self.subtrees.isEmpty && self.deleted.isEmpty
    }

    public static func emptyTree() -> BookmarkTree {
        return BookmarkTree(subtrees: [], lookup: [:], parents: [:], orphans: Set<GUID>(), deleted: Set<GUID>())
    }

    public func includesOrDeletesNode(node: BookmarkTreeNode) -> Bool {
        return self.includesOrDeletesGUID(node.recordGUID)
    }

    public func includesNode(node: BookmarkTreeNode) -> Bool {
        return self.includesGUID(node.recordGUID)
    }

    public func includesOrDeletesGUID(guid: GUID) -> Bool {
        return self.includesGUID(guid) || self.deleted.contains(guid)
    }

    public func includesGUID(guid: GUID) -> Bool {
        return self.lookup[guid] != nil
    }

    public func find(guid: GUID) -> BookmarkTreeNode? {
        return self.lookup[guid]
    }

    public func find(node: BookmarkTreeNode) -> BookmarkTreeNode? {
        return self.find(node.recordGUID)
    }

    /**
     * True if there is one subtree, and it's the Root, when overlayed.
     * We assume that the mirror will always be consistent, so what
     * this really means is that every subtree in this tree is *present*
     * in the comparison tree, or is itself rooted in a known root.
     *
     * In a fully rooted tree there can be no orphans; if our partial tree
     * includes orphans, they must be known by the comparison tree.
     */
    public func isFullyRootedIn(tree: BookmarkTree) -> Bool {
        // We don't compare against tree.deleted, because you can't *undelete*.
        return self.orphans.every(tree.includesGUID) &&
               self.subtrees.every { subtree in
                tree.includesNode(subtree) || subtree.isRoot
        }
    }

    // Recursively process an input set of structure pairs to yield complete subtrees,
    // assembling those subtrees to make a minimal set of trees.
    static func mappingsToTreeForStructureRows(mappings: [StructureRow], withNonFoldersAndEmptyFolders nonFoldersAndEmptyFolders: [BookmarkTreeNode], withDeletedRecords deleted: Set<GUID>) -> Deferred<Maybe<BookmarkTree>> {
        // Accumulate.
        var nodes: [GUID: BookmarkTreeNode] = [:]
        var parents: [GUID: GUID] = [:]
        var remainingFolders = Set<GUID>()
        var tops = Set<GUID>()
        var notTops = Set<GUID>()
        var orphans = Set<GUID>()

        // We can't immediately build the final tree, because we need to do it bottom-up!
        // So store structure, which we can figure out flat.
        var pseudoTree: [GUID: [GUID]] = mappings.groupBy({ $0.parent }, transformer: { $0.child })

        // Deal with the ones that are non-structural first.
        nonFoldersAndEmptyFolders.forEach { node in
            let guid = node.recordGUID
            nodes[guid] = node

            switch node {
            case .Folder:
                // If we end up here, it's because this folder is empty, and it won't
                // appear in structure. Assert to make sure that's true!
                assert(pseudoTree[guid] == nil)
                pseudoTree[guid] = []

                // It'll be a top unless we find it as a child in the structure somehow.
                tops.insert(guid)
            default:
                orphans.insert(guid)
            }
        }

        // Precompute every leaf node.
        mappings.forEach { row in
            parents[row.child] = row.parent
            remainingFolders.insert(row.parent)
            tops.insert(row.parent)

            // None of the children we've seen can be top, so remove them.
            notTops.insert(row.child)

            if let type = row.type {
                switch type {
                case .Folder:
                    // The child is itself a folder.
                    remainingFolders.insert(row.child)
                default:
                    nodes[row.child] = BookmarkTreeNode.NonFolder(guid: row.child)
                }
            } else {
                // This will be the case if we've shadowed a folder; we indirectly reference the original rows.
                nodes[row.child] = BookmarkTreeNode.Unknown(guid: row.child)
            }
        }

        tops.subtractInPlace(notTops)
        orphans.subtractInPlace(notTops)

        // Recursive. (Not tail recursive, but trees shouldn't be deep enough to blow the stack….)
        func nodeForGUID(guid: GUID) -> BookmarkTreeNode {
            if let already = nodes[guid] {
                return already
            }

            if !remainingFolders.contains(guid) {
                return BookmarkTreeNode.Unknown(guid: guid)
            }

            // Removing these eagerly prevents infinite recursion in the case of a cycle.
            let childGUIDs = pseudoTree[guid] ?? []
            pseudoTree.removeValueForKey(guid)
            remainingFolders.remove(guid)

            let node = BookmarkTreeNode.Folder(guid: guid, children: childGUIDs.map(nodeForGUID))
            nodes[guid] = node
            return node
        }

        // Process every record.
        // Do the not-tops first: shallower recursion.
        notTops.forEach({ nodeForGUID($0) })

        let subtrees = tops.map(nodeForGUID)        // These will all be folders.

        // Whatever we're left with in `tops` is the set of records for which we
        // didn't process a parent.
        return deferMaybe(BookmarkTree(subtrees: subtrees, lookup: nodes, parents: parents, orphans: orphans, deleted: deleted))
    }
}

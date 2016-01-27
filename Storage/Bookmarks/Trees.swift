/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private let log = Logger.syncLogger

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

    public var isUnknown: Bool {
        if case .Unknown = self {
            return true
        }
        return false
    }

    public var children: [BookmarkTreeNode]? {
        if case let .Folder(_, children) = self {
            return children
        }
        return nil
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

    // Returns false for unknowns.
    public func isSameTypeAs(other: BookmarkTreeNode) -> Bool {
        switch self {
        case .Folder:
            if case .Folder = other {
                return true
            }
        case .NonFolder:
            if case .NonFolder = other {
                return true
            }
        default:
            return false
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

    // If this tree contains the root, return it.
    public var root: BookmarkTreeNode? {
        return self.find(BookmarkRoots.RootGUID)
    }

    // Recursively process an input set of structure pairs to yield complete subtrees,
    // assembling those subtrees to make a minimal set of trees.
    static func mappingsToTreeForStructureRows(mappings: [StructureRow], withNonFoldersAndEmptyFolders nonFoldersAndEmptyFolders: [BookmarkTreeNode], withDeletedRecords deleted: Set<GUID>, alwaysIncludeRoots: Bool) -> Deferred<Maybe<BookmarkTree>> {
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

        // When we build the mirror, we always want to pretend it has our stock roots.
        // This gives us our shared basis from which to merge.
        // Doing it here means we don't need to protect the mirror database table.
        if alwaysIncludeRoots {
            // Note that we don't check whether the input already contained the roots; we
            // never change them, so it's safe to do this unconditionally.
            pseudoTree[BookmarkRoots.RootGUID] = BookmarkRoots.RootChildren
            tops.insert(BookmarkRoots.RootGUID)
            notTops.unionInPlace(BookmarkRoots.RootChildren)
            remainingFolders.unionInPlace(BookmarkRoots.RootChildren)
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
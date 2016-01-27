/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

/**
 * This class takes as input three 'trees'.
 *
 * The mirror is always complete, never contains deletions, never has
 * orphans, and has a single root.
 *
 * Each of local and buffer can contain a number of subtrees (each of which must
 * be a folder or root), a number of deleted GUIDs, and a number of orphans (records
 * with no known parent).
 *
 * It's very likely that there's almost no overlap, and thus no real conflicts to
 * resolve -- a three-way merge isn't always a bad thing -- but we won't know until
 * we compare records.
 *
 * Even though this is called 'three way merge', it also handles the case
 * of a two-way merge (one without a shared parent; for the roots, this will only
 * be on a first sync): content-based and structural merging is needed at all
 * layers of the hierarchy, so we simply generalize that to also apply to roots.
 *
 * In a sense, a two-way merge is solved by constructing a shared parent consisting of
 * roots, which are implicitly shared.
 * (Special care must be taken to not deduce that one side has deleted a root, of course,
 * as would be the case of a Sync server that doesn't contain
 * a Mobile Bookmarks folder -- the set of roots can only grow, not shrink.)
 *
 * To begin with we structurally reconcile. If necessary we will lazily fetch the
 * attributes of records in order to do a content-based reconciliation. Once we've
 * matched up any records that match (including remapping local GUIDs), we're able to
 * process _content_ changes, which is much simpler.
 *
 * We have to handle an arbitrary combination of the following structural operations:
 *
 * * Creating a folder.
 *   Created folders might now hold existing items, new items, or nothing at all.
 * * Creating a bookmark.
 *   It might be in a new folder or an existing folder.
 * * Moving one or more leaf records to an existing or new folder.
 * * Reordering the children of a folder.
 * * Deleting an entire subtree.
 * * Deleting an entire subtree apart from some moved nodes.
 * * Deleting a leaf node.
 * * Transplanting a subtree: moving a folder but not changing its children.
 *
 * And, of course, the non-structural operations such as renaming or changing URLs.
 *
 * We ignore all changes to roots themselves; the only acceptable operation on a root
 * is to change its children. The Places root is entirely immutable.
 *
 * Steps:
 * * Construct a collection of subtrees for local and buffer, and a complete tree for the mirror.
 *   The more thorough this step, the more confidence we have in consistency.
 * * Fetch all local and remote deletions. These won't be included in structure (for obvious
 *   reasons); we hold on to them explicitly so we can spot the difference between a move
 *   and a deletion.
 * * If every GUID on each side is present in the mirror, we have no new records.
 * * If a non-root GUID is present on both sides but not in the mirror, then either
 *   we're re-syncing from scratch, or (unlikely) we have a random collision.
 * * Otherwise, we have a GUID that we don't recognize. We will structure+content reconcile
 *   this later -- we first make sure we have handled any tree moves, so that the addition
 *   of a bookmark to a moved folder on A, and the addition of the same bookmark to the non-
 *   moved version of the folder, will collide successfully.
 *
 * * Walk each subtree, top-down. At each point if there are two back-pointers to
 *   the mirror node for a GUID, we have a potential conflict, and we have all three
 *   parts that we need to resolve it via a content-based or structure-based 3WM.
 *
 * When we look at a child list:
 * * It's the same. Great! Keep walking down.
 * * There are added GUIDs.
 *   * An added GUID might be a move from elsewhere. Coordinate with the removal step.
 *   * An added GUID might be a brand new record. If there are local additions too,
 *     check to see if they value-reconcile, and keep the remote GUID.
 * * There are removed GUIDs.
 *   * A removed GUID might have been deleted. Deletions win.
 *   * A missing GUID might be a move -- removed from here and added to another folder.
 *     Process this as a move.
 * * The order has changed.
 *
 * When we get to a subtree that contains no changes, we can never hit conflicts, and
 * application becomes easier.
 *
 * When we run out of subtrees on both sides, we're done.
 *
 * Match, no conflict? Apply.
 * Match, conflict? Resolve. Might involve moves from other matches!
 * No match in the mirror? Check for content match with the same parent, any position.
 * Still no match? Add.
 *
 * Note that these trees don't include values. This is because we usually don't need them:
 * if there are no conflicts, or no shared parents, we can do everything we need to do
 * at this stage simply with structure and GUIDs, and then flush rows straight from the
 * buffer into the mirror with a single SQL INSERT. We do need to fetch values later
 * in some cases: to amend child lists or otherwise construct outbound records. We do
 * need to fetch values immediately in other cases: in order to reconcile conflicts.
 * Those should ordinarily be uncommon, and because we know most of the conflicting
 * GUIDs up-front, we can prime a cache of records.
 */
class ThreeWayTreeMerger {
    let local: BookmarkTree
    let mirror: BookmarkTree
    let remote: BookmarkTree
    var merged: MergedTree
    var done: Bool = false

    let itemSource: MirrorItemSource

    // Sets computed by looking at the three trees. These are used for diagnostics,
    // to simplify operations, and for testing.

    let mirrorAllGUIDs: Set<GUID>          // Excluding deletions.
    let localAllGUIDs: Set<GUID>           // Excluding deletions.
    let remoteAllGUIDs: Set<GUID>          // Excluding deletions.
    let localAdditions: Set<GUID>          // New records added locally.
    let remoteAdditions: Set<GUID>         // New records from the server.
    let allGUIDs: Set<GUID>                // Everything added or changed locally or remotely.
    let conflictingGUIDs: Set<GUID>        // Anything added or changed both locally and remotely.

    let nonRemoteKnownGUIDs: Set<GUID>     // Everything existing, added, or deleted locally or in the mirror.


    init(local: BookmarkTree, mirror: BookmarkTree, remote: BookmarkTree, itemSource: MirrorItemSource) {
        // These are runtime-tested in merge(). assert to make sure that tests
        // don't do anything stupid, and we don't slip past those constraints.
        assert(local.isFullyRootedIn(mirror))
        assert(remote.isFullyRootedIn(mirror))
        precondition(mirror.root != nil)

        self.local = local
        self.mirror = mirror
        self.remote = remote
        self.itemSource = itemSource
        self.merged = MergedTree(mirrorRoot: self.mirror.root!)

        // We won't get here unless every local and remote orphan is correctly rooted
        // when overlaid on the mirror, so we don't need to exclude orphans here.
        self.mirrorAllGUIDs = Set<GUID>(self.mirror.lookup.keys)
        self.localAllGUIDs = Set<GUID>(self.local.lookup.keys)
        self.remoteAllGUIDs = Set<GUID>(self.remote.lookup.keys)
        self.localAdditions = localAllGUIDs.subtract(mirrorAllGUIDs)
        self.remoteAdditions = remoteAllGUIDs.subtract(mirrorAllGUIDs)
        self.allGUIDs = localAllGUIDs.union(remoteAllGUIDs)
        self.conflictingGUIDs = localAllGUIDs.intersect(remoteAllGUIDs)
        self.nonRemoteKnownGUIDs = self.mirrorAllGUIDs.union(self.localAllGUIDs).union(self.local.deleted)
    }

    private func nullOrMatch(a: String?, _ b: String?) -> Bool {
        guard let a = a, let b = b else {
            return true
        }
        return a == b
    }

    private func twoWayMergeChildListsIntoMergedNode(result: MergedTreeNode, fromLocal local: [BookmarkTreeNode], remote: [BookmarkTreeNode]) throws {
        result.structureState = MergeState.New(value: BookmarkTreeNode.Folder(guid: result.guid, children: local))
        result.mergedChildren = nil      // TODO
    }

    // This will never be called with two .Unknown values.
    private func twoWayMerge(guid: GUID, localNode: BookmarkTreeNode, remoteNode: BookmarkTreeNode) throws -> MergedTreeNode {

        // These really shouldn't occur in a two-way merge, but there we are.
        if remoteNode.isUnknown {
            if localNode.isUnknown {
                preconditionFailure("Two unknown nodes!")
            }

            log.debug("Taking local node in two-way merge: remote bafflingly unchanged.")
            return MergedTreeNode.forLocal(localNode)
        } else if localNode.isUnknown {
            log.debug("Taking remote node in two-way merge: local bafflingly unchanged.")
            return MergedTreeNode.forRemote(remoteNode)
        }

        let result = MergedTreeNode(guid: guid, mirror: nil)
        result.local = localNode
        result.remote = remoteNode

        // Value merge. This applies regardless.
        log.debug("We are lazy: taking remote value for \(guid) in two-way merge.")
        result.valueState = MergeState.Remote       // TODO: value-based merge.

        switch localNode {
        case let .Folder(_, localChildren):
            if case let .Folder(_, remoteChildren) = remoteNode {
                // Structural merge.
                if localChildren.sameElements(remoteChildren, f: { $0.recordGUID == $1.recordGUID }) {
                    // Great!
                    log.debug("Local and remote records have same children in two-way merge.")
                    result.structureState = MergeState.New(value: localNode)
                } else {
                    // Merge the two folder lists.
                    // We know that each side is internally consistent: that is, each
                    // node in this list is present in the tree once only. But when we
                    // combine the two lists, we might be inadvertently duplicating a
                    // record that has already been, or will soon be, found in the other
                    // tree. We need to be careful to make sure that we don't feature
                    // a node in the tree more than once.
                    // Remember to check deletions.
                    log.debug("Local and remote records have different children. Merging.")
                    try self.twoWayMergeChildListsIntoMergedNode(result, fromLocal: localChildren, remote: remoteChildren)
                }
                return result
            }

        case .NonFolder:
            if case .NonFolder = remoteNode {
                log.debug("Two non-folders with GUID \(guid) collide. Taking remote.")
                return result
            }

        default:
            break
        }

        // Otherwise, this must be a GUID collision between different types.
        // TODO: Assign a new GUID to the local record
        // but do not upload a deletion; these shouldn't merge.
        log.debug("Remote and local records with same GUID \(guid) but different types. Consistency error.")
        throw BookmarksMergeConsistencyError()
    }

    private func threeWayMerge(guid: GUID, localNode: BookmarkTreeNode, remoteNode: BookmarkTreeNode, mirrorNode: BookmarkTreeNode) throws -> MergedTreeNode {
        // TODO: three-way merge!
        return try self.twoWayMerge(guid, localNode: localNode, remoteNode: remoteNode)
    }

    // We'll end up looking at deletions and such as we go.
    func mergeNode(guid: GUID, localNode: BookmarkTreeNode?, mirrorNode: BookmarkTreeNode?, remoteNode: BookmarkTreeNode?) throws -> MergedTreeNode {
        log.debug("Merging nodes with GUID \(guid).")

        // We'll never get here with no nodes at all… right?
        precondition((localNode != nil) || (mirrorNode != nil) || (remoteNode != nil))

        // Note that not all of the input nodes must share a GUID: we might have decided, based on
        // value comparison in an earlier recursive call, that a local node will be replaced by a
        // remote node, and we'll need to mark the local GUID as a deletion, using its values and
        // structure during our reconciling.
        // But we will never have the mirror and remote differ.
        precondition(nullOrMatch(remoteNode?.recordGUID, mirrorNode?.recordGUID))
        precondition(nullOrMatch(remoteNode?.recordGUID, guid))
        precondition(nullOrMatch(mirrorNode?.recordGUID, guid))

        // If we ended up here with two unknowns, just proceed down the mirror.
        // We know we have a mirror, else we'd have a non-unknown edge.
        if (localNode?.isUnknown ?? true) && (remoteNode?.isUnknown ?? true) {
            precondition(mirrorNode != nil)
            log.debug("Record \(guid) didn't change from mirror.")
            return MergedTreeNode.forUnchanged(mirrorNode!)
        }

        guard let mirrorNode = mirrorNode else {
            // No mirror node: at most a two-way merge.
            if let loc = localNode where !loc.isUnknown {
                if let rem = remoteNode {
                    // Two-way merge; probably a disconnect-reconnect scenario.
                    return try self.twoWayMerge(guid, localNode: loc, remoteNode: rem)
                }

                // No remote. Node only exists locally.
                // However! The children might be mentioned in the mirror or
                // remote tree.
                // TODO: process children.
                log.debug("Node \(guid) only exists locally.")
                return MergedTreeNode.forLocal(loc)
            }

            // No local.

            guard let rem = remoteNode where !rem.isUnknown else {
                // No remote!
                // This should not occur: we have preconditions above.
                preconditionFailure("Unexpectedly got past our preconditions!")
            }

            // Node only exists remotely. Take it.
            // TODO: process children.
            log.debug("Node \(guid) only exists remotely.")
            return MergedTreeNode.forRemote(rem)
        }

        // We have a mirror node.
        if let loc = localNode where !loc.isUnknown {
            if let rem = remoteNode where !rem.isUnknown {
                log.debug("Both local and remote changes to a mirror item. Resolving conflict.")
                return try self.threeWayMerge(guid, localNode: loc, remoteNode: rem, mirrorNode: mirrorNode)
            } else {
                log.debug("Local-only change to a mirror item.")
                // Easy, but watch out for value changes or deletions to our children.
                // TODO: process children.
                return MergedTreeNode.forLocal(loc, mirror: mirrorNode)
            }
        } else {
            if let rem = remoteNode where !rem.isUnknown {
                log.debug("Remote-only change to a mirror item.")
                // Easy, but watch out for value changes or deletions to our children.
                // TODO: process children.
                return MergedTreeNode.forRemote(rem, mirror: mirrorNode)
            } else {
                log.debug("Record \(guid) didn't change from mirror.")
                return MergedTreeNode.forUnchanged(mirrorNode)
            }
        }
    }

    // This should only be called once.
    func produceMergedTree() -> Deferred<Maybe<MergedTree>> {
        if self.done {
            return deferMaybe(self.merged)
        }

        let root = self.merged.root
        assert((root.mirror?.children?.count ?? 0) == BookmarkRoots.RootChildren.count)

        // Get to walkin'.
        root.structureState = MergeState.Unchanged      // We never change the root.
        root.valueState = MergeState.Unchanged

        do {
            try root.mergedChildren = root.mirror!.children!.map {
                let guid = $0.recordGUID
                let loc = self.local.find(guid)
                let mir = self.mirror.find(guid)
                let rem = self.remote.find(guid)
                return try self.mergeNode(guid, localNode: loc, mirrorNode: mir, remoteNode: rem)
            }
        } catch let error as BookmarksMergeConsistencyError {
            return deferMaybe(error)
        } catch {
            return deferMaybe(BookmarksMergeConsistencyError())
        }

        self.done = true
        return deferMaybe(self.merged)
    }

    func produceMergeResultFromMergedTree(mergedTree: MergedTree) -> Deferred<Maybe<BookmarksMergeResult>> {
        let upstream = UpstreamCompletionOp()
        let buffer = BufferCompletionOp()
        let local = LocalOverrideCompletionOp()

        // TODO: walk the merged tree to produce filled ops.
        return deferMaybe(BookmarksMergeResult(uploadCompletion: upstream, overrideCompletion: local, bufferCompletion: buffer))
    }

    func merge() -> Deferred<Maybe<BookmarksMergeResult>> {

        // Both local and remote should reach a single root when overlayed. If not, it means that
        // the tree is inconsistent -- there isn't a full tree present either on the server (or local)
        // or in the mirror, or the changes aren't congruent in some way. If we reach this state, we
        // cannot proceed.
        //
        // This is assert()ed in the initializer, too, so that we crash hard and early in developer builds and tests.

        if !self.local.isFullyRootedIn(self.mirror) {
            log.warning("Local bookmarks not fully rooted when overlayed on mirror. This is most unusual.")
            return deferMaybe(BookmarksMergeErrorTreeIsUnrooted(roots: self.local.subtreeGUIDs))
        }

        if !self.remote.isFullyRootedIn(mirror) {
            log.warning("Remote bookmarks not fully rooted when overlayed on mirror. Partial read or write in buffer?")

            // TODO: request recovery.
            return deferMaybe(BookmarksMergeErrorTreeIsUnrooted(roots: self.remote.subtreeGUIDs))
        }

        log.debug("Processing \(self.localAllGUIDs.count) local changes and \(self.remoteAllGUIDs.count) remote.")
        log.debug("\(self.local.subtrees.count) local subtrees and \(self.remote.subtrees.count) remote subtrees.")
        log.debug("Local is adding \(self.localAdditions.count) records, and remote is adding \(self.remoteAdditions.count).")

        if !conflictingGUIDs.isEmpty {
            log.warning("Expecting conflicts between local and remote: \(conflictingGUIDs.joinWithSeparator(", ")).")
        }

        return self.produceMergedTree() >>== self.produceMergeResultFromMergedTree
    }
}
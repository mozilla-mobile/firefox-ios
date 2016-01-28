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
 * Each of local and remote can contain a number of subtrees (each of which must
 * be a folder or root), a number of deleted GUIDs, and a number of orphans (records
 * with no known parent).
 *
 * As output it produces a merged tree. The tree contains the new structure,
 * including every record that we're keeping, and also makes note of any deletions.
 *
 * The merged tree can be walked to yield a set of operations against the original
 * three trees. Those operations will make the upstream source and local storage
 * match the merge output.
 *
 * It's very likely that there's almost no overlap between local and remote, and
 * thus no real conflicts to resolve -- a three-way merge isn't always a bad thing
 * -- but we won't know until we compare records.
 *
 *
 * Even though this is called 'three way merge', it also handles the case
 * of a two-way merge (one without a shared parent; for the roots, this will only
 * be on a first sync): content-based and structural merging is needed at all
 * layers of the hierarchy, so we simply generalize that to also apply to roots.
 *
 * In a sense, a two-way merge is solved by constructing a shared parent consisting of
 * roots, which are implicitly shared.
 *
 * (Special care must be taken to not deduce that one side has deleted a root, of course,
 * as would be the case of a Sync server that doesn't contain
 * a Mobile Bookmarks folder -- the set of roots can only grow, not shrink.)
 *
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
 * * Walk each subtree, top-down. At each point if there are two back-pointers to
 *   the mirror node for a GUID, we have a potential conflict, and we have all three
 *   parts that we need to resolve it via a content-based or structure-based 3WM.
 *
 * Observations:
 * * If every GUID on each side is present in the mirror, we have no new records.
 * * If a non-root GUID is present on both sides but not in the mirror, then either
 *   we're re-syncing from scratch, or (unlikely) we have a random collision.
 * * Otherwise, we have a GUID that we don't recognize. We will structure+content reconcile
 *   this later -- we first make sure we have handled any tree moves, so that the addition
 *   of a bookmark to a moved folder on A, and the addition of the same bookmark to the non-
 *   moved version of the folder, will collide successfully.
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

    // Don't merge twice.
    var mergeAttempted: Bool = false

    let itemSource: MirrorItemSource

    // Sets computed by looking at the three trees. These are used for diagnostics,
    // to simplify operations, and for testing.
    // TODO: pre-fetch items from `itemSource` using allChangedGUIDs.

    let mirrorAllGUIDs: Set<GUID>          // Excluding deletions.
    let localAllGUIDs: Set<GUID>           // Excluding deletions.
    let remoteAllGUIDs: Set<GUID>          // Excluding deletions.
    let localAdditions: Set<GUID>          // New records added locally, not present in the mirror.
    let remoteAdditions: Set<GUID>         // New records from the server, not present in the mirror.
    let allDeletions: Set<GUID>            // Records deleted locally or remotely.
    let allChangedGUIDs: Set<GUID>         // Everything added or changed locally or remotely.
    let conflictingGUIDs: Set<GUID>        // Anything added or changed both locally and remotely.

    let nonRemoteKnownGUIDs: Set<GUID>     // Everything existing, added, or deleted locally or in the mirror.

    // For now, track just one list. We might need to split this later.
    var done: Set<GUID> = Set()

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
        self.mirrorAllGUIDs = self.mirror.modified
        self.localAllGUIDs = self.local.modified
        self.remoteAllGUIDs = self.remote.modified
        self.localAdditions = localAllGUIDs.subtract(mirrorAllGUIDs)
        self.remoteAdditions = remoteAllGUIDs.subtract(mirrorAllGUIDs)
        self.allDeletions = self.local.deleted.union(self.remote.deleted)
        self.allChangedGUIDs = localAllGUIDs.union(self.remoteAllGUIDs)
        self.conflictingGUIDs = localAllGUIDs.intersect(remoteAllGUIDs)
        self.nonRemoteKnownGUIDs = self.mirrorAllGUIDs.union(self.localAllGUIDs).union(self.local.deleted)
    }

    private func nullOrMatch(a: String?, _ b: String?) -> Bool {
        guard let a = a, let b = b else {
            return true
        }
        return a == b
    }

    // TODO: can we merge these three helpers?
    private func takeMirrorChildrenInMergedNode(result: MergedTreeNode) throws {
        guard let mirrorChildren = result.mirror?.children else {
            preconditionFailure("Expected children.")
        }

        let out: [MergedTreeNode] = try mirrorChildren.map { child in
            // TODO: handle deletions. That might change the below from 'Unchanged'
            // to 'New'.
            let childGUID = child.recordGUID
            let localCounterpart = self.local.find(childGUID)
            let remoteCounterpart = self.remote.find(childGUID)
            return try self.mergeNode(childGUID, localNode: localCounterpart, mirrorNode: child, remoteNode: remoteCounterpart)
        }

        result.mergedChildren = out
        result.structureState = MergeState.Unchanged
    }

    private func oneWayMergeChildListsIntoMergedNode(result: MergedTreeNode, fromRemote remote: [BookmarkTreeNode]) throws {
        // TODO: this should be sensibly co-recursive; just as with merging
        // the child lists in the two-way and three-way merge, we need
        // to handle deletions, moves, tracking of seen items, etc.
        // This is thus temporary!
        let out: [MergedTreeNode] = try remote.map { child in
            // TODO: handle deletions.
            let childGUID = child.recordGUID
            let localCounterpart = self.local.find(childGUID)
            return try self.mergeNode(childGUID, localNode: localCounterpart, mirrorNode: result.mirror, remoteNode: child)
        }
        let newStructure = out.map { $0.asMergedTreeNode() }
        result.mergedChildren = out
        result.structureState = MergeState.New(value: BookmarkTreeNode.Folder(guid: result.guid, children: newStructure))
    }

    private func oneWayMergeChildListsIntoMergedNode(result: MergedTreeNode, fromLocal local: [BookmarkTreeNode]) throws {
        // TODO: this should be sensibly co-recursive; just as with merging
        // the child lists in the two-way and three-way merge, we need
        // to handle deletions, moves, tracking of seen items, etc.
        // This is thus temporary!
        let out: [MergedTreeNode] = try local.map { child in
            // TODO: handle deletions.
            let childGUID = child.recordGUID
            let remoteCounterpart = self.remote.find(childGUID)
            return try self.mergeNode(childGUID, localNode: child, mirrorNode: result.mirror, remoteNode: remoteCounterpart)
        }
        let newStructure = out.map { $0.asMergedTreeNode() }
        result.mergedChildren = out
        result.structureState = MergeState.New(value: BookmarkTreeNode.Folder(guid: result.guid, children: newStructure))
    }

    private func twoWayMergeChildListsIntoMergedNode(result: MergedTreeNode, fromLocal local: [BookmarkTreeNode], remote: [BookmarkTreeNode]) throws {
        // The most trivial implementation: take everything in the first list, then append
        // everything new in the second list.
        // Anything present in both is queued up to be resolved.
        // We can't get away from handling deletions and moves, etc. -- one might have
        // created a folder on two devices and moved existing items on one, some of which
        // might have been deleted on the other.
        // This kind of shit is why bookmark sync is hard.
        var out: [MergedTreeNode] = []
        var seen: Set<GUID> = Set()

        // Do a recursive merge of each child.
        try remote.forEach { rem in
            let guid = rem.recordGUID
            seen.insert(guid)

            let mir = self.mirror.find(guid)
            let loc = self.local.find(guid)
            let locallyDeleted = self.local.deleted.contains(guid)

            if locallyDeleted {
                // It was locally deleted. This would be good enough for us,
                // but we need to ensure that any remote children are recursively
                // deleted or handled as orphans.
                // TODO
                return
            }

            let m = try self.mergeNode(guid, localNode: loc, mirrorNode: mir, remoteNode: rem)
            out.append(m)
        }

        try local.forEach { loc in
            let guid = loc.recordGUID
            if seen.contains(guid) {
                return
            }

            let mir = self.mirror.find(guid)
            let rem = self.remote.find(guid)
            let remotelyDeleted = self.remote.deleted.contains(guid)

            if remotelyDeleted {
                // It was remotely deleted. This would be good enough for us,
                // but we need to ensure that any local children are recursively
                // deleted or handled as orphans.
                // TODO
                return
            }

            let m = try self.mergeNode(guid, localNode: loc, mirrorNode: mir, remoteNode: rem)
            out.append(m)
        }

        let newStructure = out.map { $0.asMergedTreeNode() }
        result.mergedChildren = out
        result.structureState = MergeState.New(value: BookmarkTreeNode.Folder(guid: result.guid, children: newStructure))
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
        // TODO: three-way merge! Particularly important for value-based merging,
        // but we can also do a better job of merging child lists.
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

        // Immediately mark this GUID -- and the local GUID, if it differs -- as done.
        // This avoids us repeating this in each branch, and avoids the possibility of
        // certain moves causing us to hit the same node again.
        // We don't need to actually check this list until:
        // 1. We walk the local tree as well as the remote tree. At this point we
        //    should skip the local records that we've already seen.
        // 2. We do content-based reconciling, in which case we need to avoid processing
        //    twice. When we do the content lookup, we should also make sure that
        //    we're not going to run into the node by GUID later!
        self.done.insert(guid)
        if let otherGUID = localNode?.recordGUID where otherGUID != guid {
            self.done.insert(otherGUID)
        }

        func takeRemoteAndMergeChildren(remote: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) throws -> MergedTreeNode {
            // Easy, but watch out for value changes or deletions to our children.
            let merged = MergedTreeNode.forRemote(remote, mirror: mirror)
            if case let .Folder(_, children) = remote {
                log.debug("… and it's a folder. Taking remote children.")
                try self.oneWayMergeChildListsIntoMergedNode(merged, fromRemote: children)
            }
            return merged
        }

        func takeLocalAndMergeChildren(local: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) throws -> MergedTreeNode {
            // Easy, but watch out for value changes or deletions to our children.
            let merged = MergedTreeNode.forLocal(local, mirror: mirror)
            if case let .Folder(_, children) = local {
                log.debug("… and it's a folder. Taking local children.")
                try self.oneWayMergeChildListsIntoMergedNode(merged, fromLocal: children)
            }
            return merged
        }

        func takeMirrorNode(mirror: BookmarkTreeNode) throws -> MergedTreeNode {
            let merged = MergedTreeNode.forUnchanged(mirror)
            if case .Folder = mirror {
                try self.takeMirrorChildrenInMergedNode(merged)
            }
            return merged
        }

        // If we ended up here with two unknowns, just proceed down the mirror.
        // We know we have a mirror, else we'd have a non-unknown edge.
        if (localNode?.isUnknown ?? true) && (remoteNode?.isUnknown ?? true) {
            precondition(mirrorNode != nil)
            log.debug("Record \(guid) didn't change from mirror.")

            self.done.insert(guid)
            return try takeMirrorNode(mirrorNode!)
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
                log.debug("Node \(guid) only exists locally.")
                return try takeLocalAndMergeChildren(loc)
            }

            // No local.

            guard let rem = remoteNode where !rem.isUnknown else {
                // No remote!
                // This should not occur: we have preconditions above.
                preconditionFailure("Unexpectedly got past our preconditions!")
            }

            // Node only exists remotely. Take it.
            log.debug("Node \(guid) only exists remotely.")
            return try takeRemoteAndMergeChildren(rem)
        }

        // We have a mirror node.
        if let loc = localNode where !loc.isUnknown {
            if let rem = remoteNode where !rem.isUnknown {
                log.debug("Both local and remote changes to a mirror item. Resolving conflict.")
                return try self.threeWayMerge(guid, localNode: loc, remoteNode: rem, mirrorNode: mirrorNode)
            }
            log.debug("Local-only change to a mirror item.")
            return try takeLocalAndMergeChildren(loc, mirror: mirrorNode)
        }

        if let rem = remoteNode where !rem.isUnknown {
            log.debug("Remote-only change to a mirror item.")
            return try takeRemoteAndMergeChildren(rem, mirror: mirrorNode)
        }

        log.debug("Record \(guid) didn't change from mirror.")
        return try takeMirrorNode(mirrorNode)
    }

    // This should only be called once.
    func produceMergedTree() -> Deferred<Maybe<MergedTree>> {
        if self.mergeAttempted {
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

        // Now walk down from the mirror root again, this time taking all of the unmerged local branches.
        // TODO

        self.mergeAttempted = true
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
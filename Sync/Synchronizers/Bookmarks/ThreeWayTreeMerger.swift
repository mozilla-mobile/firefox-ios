/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

private func negate<T>(f: T throws -> Bool) -> T throws -> Bool {
    return { try !f($0) }
}

extension CollectionType {
    func exclude(predicate: (Self.Generator.Element) throws -> Bool) throws -> [Self.Generator.Element] {
        return try self.filter(negate(predicate))
    }
}

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

    let bufferItemSource: BufferItemSource
    let mirrorItemSource: MirrorItemSource
    let localItemSource: LocalItemSource

    // Sets computed by looking at the three trees. These are used for diagnostics,
    // to simplify operations, to pre-fetch items for value comparison, and for testing.

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

    // Local branches down which we did not recurse on our first pass.
    var localQueue = nodeOnceOnlyStack()

    init(local: BookmarkTree, mirror: BookmarkTree, remote: BookmarkTree, localItemSource: LocalItemSource, mirrorItemSource: MirrorItemSource, bufferItemSource: BufferItemSource) {
        precondition(mirror.root != nil)
        assert((mirror.root!.children?.count ?? 0) == BookmarkRoots.RootChildren.count)
        precondition(mirror.orphans.isEmpty)
        precondition(mirror.deleted.isEmpty)
        precondition(mirror.subtrees.count == 1)

        // These are runtime-tested in merge(). assert to make sure that tests
        // don't do anything stupid, and we don't slip past those constraints.
        assert(local.isFullyRootedIn(mirror))
        assert(remote.isFullyRootedIn(mirror))

        self.local = local
        self.mirror = mirror
        self.remote = remote
        self.bufferItemSource = bufferItemSource
        self.mirrorItemSource = mirrorItemSource
        self.localItemSource = localItemSource
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

    /**
     * When we have a folder match and new records on each side -- records
     * not mentioned in the buffer -- it's possible that the new records
     * are the same but have different GUIDs.
     * This function will look at value matches to identify a local
     * equivalent in this folder, returning nil if none are found.
     *
     * Note that we don't match records that have already been matched, and
     * we don't match any for which a GUID is known in the mirror or remote.
     */
    private func findNewLocalNodeMatchingContentOfRemoteNote(remote: BookmarkTreeNode, inFolder parent: GUID, withLocalChildren children: [BookmarkTreeNode], havingSeen seen: Set<GUID>) -> BookmarkTreeNode? {
        // TODO: don't compute this list once per incoming child! Profile me.
        let candidates = children.filter { child in
            let childGUID = child.recordGUID
            return !seen.contains(childGUID) &&                   // Not already used in this folder.
                   !self.remoteAdditions.contains(childGUID) &&   // Not locally and remotely added with same GUID.
                   !self.remote.deleted.contains(childGUID) &&    // Not remotely deleted.
                   !self.done.contains(childGUID)                 // Not already processed elsewhere in the tree.
        }

        guard let remoteValue = self.bufferItemSource.getBufferItemWithGUID(remote.recordGUID).value.successValue else {
            log.error("Couldn't find remote value for \(remote.recordGUID).")
            return nil
        }

        let guids = candidates.map { $0.recordGUID }
        guard let items = self.localItemSource.getLocalItemsWithGUIDs(guids).value.successValue else {
            log.error("Couldn't find local values for \(candidates.count) candidates.")
            return nil
        }

        // Return the first candidate that's a value match.
        guard let localItem = (guids.flatMap { items[$0] }.find { $0.sameAs(remoteValue) }) else {
            log.debug("Didn't find a local value match for new remote record \(remote.recordGUID).")
            return nil
        }

        log.debug("Found a local match \(localItem.guid) for new remote record \(remote.recordGUID) in parent \(parent).")
        // Find the original contributing child node by GUID.
        return children.find { $0.recordGUID == localItem.guid }
    }

    private func takeMirrorChildrenInMergedNode(result: MergedTreeNode) throws {
        guard let mirrorChildren = result.mirror?.children else {
            preconditionFailure("Expected children.")
        }

        let out: [MergedTreeNode] = try mirrorChildren.flatMap { child in
            // TODO: handle deletions. That might change the below from 'Unchanged'
            // to 'New'.
            let childGUID = child.recordGUID
            if self.done.contains(childGUID) {
                log.warning("Not taking mirror child \(childGUID): already done. This is unexpected.")
                return nil
            }
            let localCounterpart = self.local.find(childGUID)
            let remoteCounterpart = self.remote.find(childGUID)
            return try self.mergeNode(childGUID, localNode: localCounterpart, mirrorNode: child, remoteNode: remoteCounterpart)
        }

        result.mergedChildren = out
        result.structureState = MergeState.Unchanged
    }

    private func oneWayMergeChildListsIntoMergedNode(result: MergedTreeNode, fromRemote remote: BookmarkTreeNode) throws {
        guard case .Folder = remote else {
            preconditionFailure("Expected folder from which to merge children.")
        }

        result.structureState = MergeState.Remote       // If the list changes, this will switch to .New.
        try self.mergeChildListsIntoMergedNode(result, fromLocal: nil, remote: remote, mirror: self.mirror.find(remote.recordGUID))
    }

    private func oneWayMergeChildListsIntoMergedNode(result: MergedTreeNode, fromLocal local: BookmarkTreeNode) throws {
        guard case .Folder = local else {
            preconditionFailure("Expected folder from which to merge children.")
        }

        result.structureState = MergeState.Local       // If the list changes, this will switch to .New.
        try self.mergeChildListsIntoMergedNode(result, fromLocal: local, remote: nil, mirror: self.mirror.find(local.recordGUID))
    }

    private func mergeChildListsIntoMergedNode(result: MergedTreeNode, fromLocal local: BookmarkTreeNode?, remote: BookmarkTreeNode?, mirror: BookmarkTreeNode?) throws {
        precondition(local != nil || remote != nil, "Expected either local or remote folder for merge.")

        // The most trivial implementation: take everything in the first list, then append
        // everything new in the second list.
        // Anything present in both is resolved.
        // We can't get away from handling deletions and moves, etc. -- one might have
        // created a folder on two devices and moved existing items on one, some of which
        // might have been deleted on the other.
        // This kind of shit is why bookmark sync is hard.
        // See each of the test cases in TestBookmarkTreeMerging, which have helpful diagrams.
        var out: [MergedTreeNode] = []
        var seen: Set<GUID> = Set()

        var changed = false

        func processRemoteOrphansForNode(node: BookmarkTreeNode) throws {
            // Now we recursively merge down into our list of orphans. If those contain deleted
            // subtrees, excess leaves will be flattened up; we'll get a single list of nodes
            // here, and we'll take them as additional children.

            let guid = node.recordGUID
            func isLocallyDeleted(child: BookmarkTreeNode) throws -> Bool {
                return try checkForLocalDeletionOfRemoteNode(child, mirrorNode: self.mirror.find(child.recordGUID))
            }

            guard let orphans = try node.children?.exclude(isLocallyDeleted) where !orphans.isEmpty else {
                log.debug("No remote orphans from local deletion of \(guid).")
                return
            }

            let mergedOrphans = try orphans.map { (orphan: BookmarkTreeNode) throws -> MergedTreeNode in
                let guidO = orphan.recordGUID
                let locO = self.local.find(guidO)
                let remO = orphan
                let mirO = self.mirror.find(guidO)
                log.debug("Merging up remote orphan \(guidO).")
                return try self.mergeNode(guidO, localNode: locO, mirrorNode: mirO, remoteNode: remO)
            }

            log.debug("Collected \(mergedOrphans.count) remote orphans for deleted folder \(guid).")
            changed = true
            out.appendContentsOf(mergedOrphans)
        }

        func processLocalOrphansForNode(node: BookmarkTreeNode) throws {
            // Now we recursively merge down into our list of orphans. If those contain deleted
            // subtrees, excess leaves will be flattened up; we'll get a single list of nodes
            // here, and we'll take them as additional children.

            let guid = node.recordGUID
            func isRemotelyDeleted(child: BookmarkTreeNode) throws -> Bool {
                return try checkForRemoteDeletionOfLocalNode(child, mirrorNode: self.mirror.find(child.recordGUID))
            }

            guard let orphans = try node.children?.exclude(isRemotelyDeleted) where !orphans.isEmpty else {
                log.debug("No local orphans from remote deletion of \(guid).")
                return
            }

            let mergedOrphans = try orphans.map { (orphan: BookmarkTreeNode) throws -> MergedTreeNode in
                let guidO = orphan.recordGUID
                let locO = orphan
                let remO = self.remote.find(guidO)
                let mirO = self.mirror.find(guidO)
                log.debug("Merging up local orphan \(guidO).")
                return try self.mergeNode(guidO, localNode: locO, mirrorNode: mirO, remoteNode: remO)
            }

            log.debug("Collected \(mergedOrphans.count) local orphans for deleted folder \(guid).")
            changed = true
            out.appendContentsOf(mergedOrphans)
        }

        func checkForLocalDeletionOfRemoteNode(node: BookmarkTreeNode, mirrorNode: BookmarkTreeNode?) throws -> Bool {
            let guid = node.recordGUID

            guard self.local.deleted.contains(guid) else {
                return false
            }

            // It was locally deleted. This would be good enough for us,
            // but we need to ensure that any remote children are recursively
            // deleted or handled as orphans.
            log.warning("Quietly accepting local deletion of record \(guid).")
            changed = true

            self.merged.deleteRemotely.insert(guid)
            self.merged.acceptLocalDeletion.insert(guid)
            if mirrorNode != nil {
                self.merged.deleteFromMirror.insert(guid)
            }

            try processRemoteOrphansForNode(node)
            return true
        }

        func checkForRemoteDeletionOfLocalNode(node: BookmarkTreeNode, mirrorNode: BookmarkTreeNode?) throws -> Bool {
            let guid = node.recordGUID

            guard self.remote.deleted.contains(guid) else {
                return false
            }

            // It was remotely deleted. This would be good enough for us,
            // but we need to ensure that any local children are recursively
            // deleted or handled as orphans.
            log.warning("Quietly accepting remote deletion of record \(guid).")

            self.merged.deleteLocally.insert(guid)
            self.merged.acceptRemoteDeletion.insert(guid)
            if mirrorNode != nil {
                self.merged.deleteFromMirror.insert(guid)
            }

            try processLocalOrphansForNode(node)
            return true
        }

        // Do a recursive merge of each child.
        if let remote = remote, children = remote.children {
            try children.forEach { rem in
                let guid = rem.recordGUID
                seen.insert(guid)

                if self.done.contains(guid) {
                    log.debug("Processing children of \(result.guid). Child \(guid) already seen elsewhere!")
                    return
                }

                if try checkForLocalDeletionOfRemoteNode(remote, mirrorNode: self.mirror.find(guid)) {
                    return
                }

                let mir = self.mirror.find(guid)
                if let localByGUID = self.local.find(guid) {
                    // Let's check the parent of the local match. If it differs, then the matching
                    // record is elsewhere in the local tree, and we need to decide which place to
                    // keep it.
                    // We do so by finding the modification time of the parent on each side,
                    // unless one of the records is explicitly non-modified.
                    if let localParentGUID = self.local.parents[guid] {

                        // Oh hey look! Ad hoc three-way merge!
                        let mirrorParentGUID = self.mirror.parents[guid]

                        if localParentGUID != result.guid {
                            log.debug("Local child \(guid) is in folder \(localParentGUID), but remotely is in \(result.guid).")
                            if mirrorParentGUID != localParentGUID {
                                log.debug("… and locally it has changed since our last sync, moving from \(mirrorParentGUID) to \(localParentGUID).")

                                // Find out which parent is most recent.
                                if let localRecords = self.localItemSource.getLocalItemsWithGUIDs([localParentGUID, guid]).value.successValue,
                                   let remoteRecords = self.bufferItemSource.getBufferItemsWithGUIDs([result.guid, guid]).value.successValue {

                                    let latestLocalTimestamp = max(localRecords[guid]?.localModified ?? 0, localRecords[localParentGUID]?.localModified ?? 0)
                                    let latestRemoteTimestamp = max(remoteRecords[guid]?.serverModified ?? 0, remoteRecords[result.guid]?.serverModified ?? 0)
                                    log.debug("Latest remote timestamp: \(latestRemoteTimestamp). Latest local timestamp: \(latestLocalTimestamp).")

                                    if latestLocalTimestamp > latestRemoteTimestamp {
                                        log.debug("Keeping record in its local position. We'll merge these later.")
                                        return
                                    }

                                    log.debug("Taking remote, because it's later. Merging now.")
                                }
                            } else {
                                log.debug("\(guid) didn't move from \(mirrorParentGUID) since our last sync. Taking remote parent.")
                            }
                        } else {
                            log.debug("\(guid) is locally in \(localParentGUID) and remotely in \(result.guid). Easy.")
                        }
                    }

                    out.append(try self.mergeNode(guid, localNode: localByGUID, mirrorNode: mir, remoteNode: rem))
                    return
                }

                // We don't ever have to handle moves in this case: we only search this directory.
                let localByContent: BookmarkTreeNode?
                if let localChildren = local?.children {
                    localByContent = self.findNewLocalNodeMatchingContentOfRemoteNote(rem, inFolder: result.guid, withLocalChildren: localChildren, havingSeen: seen)
                } else {
                    localByContent = nil
                }
                out.append(try self.mergeNode(guid, localNode: localByContent, mirrorNode: mir, remoteNode: rem))
            }
        }

        if let local = local, children = local.children {
            try children.forEach { loc in
                let guid = loc.recordGUID
                if seen.contains(guid) {
                    log.debug("Already saw local child \(guid).")
                    return
                }

                if self.done.contains(guid) {
                    log.debug("Already saw local child \(guid) elsewhere.")
                    return
                }

                if try checkForRemoteDeletionOfLocalNode(loc, mirrorNode: self.mirror.find(guid)) {
                    return
                }

                let mir = self.mirror.find(guid)
                let rem = self.remote.find(guid)
                changed = true
                out.append(try self.mergeNode(guid, localNode: loc, mirrorNode: mir, remoteNode: rem))
            }
        }

        // Walk the mirror node's children. Any that are deleted on only one side might contribute
        // orphans, so descend into those nodes' children on the other side.
        if let expectedParent = mirror?.recordGUID, mirrorChildren = mirror?.children {
            try mirrorChildren.forEach { child in
                let potentiallyDeleted = child.recordGUID
                if seen.contains(potentiallyDeleted) || self.done.contains(potentiallyDeleted) {
                    return
                }

                let locallyDeleted = self.local.deleted.contains(potentiallyDeleted)
                let remotelyDeleted = self.remote.deleted.contains(potentiallyDeleted)
                if !locallyDeleted && !remotelyDeleted {
                    log.debug("Mirror child \(potentiallyDeleted) no longer here, but not deleted on either side: must be elsewhere.")
                    return
                }

                if locallyDeleted && remotelyDeleted {
                    log.debug("Mirror child \(potentiallyDeleted) was deleted both locally and remoted. We cool.")
                    self.merged.deleteFromMirror.insert(potentiallyDeleted)
                    self.merged.acceptLocalDeletion.insert(potentiallyDeleted)
                    self.merged.acceptRemoteDeletion.insert(potentiallyDeleted)
                    return
                }

                if locallyDeleted {
                    // See if the remote side still thinks this is the parent.
                    let parent = self.remote.parents[potentiallyDeleted]
                    if parent == nil || parent == expectedParent {
                        log.debug("Remote still thinks \(potentiallyDeleted) is here. Processing for orphans.")
                        try processRemoteOrphansForNode(self.remote.find(potentiallyDeleted)!)
                    }

                    // Accept the local deletion, and make a note to apply it elsewhere.
                    self.merged.deleteFromMirror.insert(potentiallyDeleted)
                    self.merged.deleteRemotely.insert(potentiallyDeleted)
                    self.merged.acceptLocalDeletion.insert(potentiallyDeleted)
                    return
                }

                // Remotely deleted.

                let parent = self.local.parents[potentiallyDeleted]
                if parent == nil || parent == expectedParent {
                    log.debug("Local still thinks \(potentiallyDeleted) is here. Processing for orphans.")
                    try processLocalOrphansForNode(self.local.find(potentiallyDeleted)!)

                    // Accept the remote deletion, and make a note to apply it elsewhere.
                    self.merged.deleteFromMirror.insert(potentiallyDeleted)
                    self.merged.deleteLocally.insert(potentiallyDeleted)
                    self.merged.acceptRemoteDeletion.insert(potentiallyDeleted)
                }
            }
        }

        log.debug("Setting \(result.guid)'s children to \(out.map { $0.guid }).")
        result.mergedChildren = out

        // If the child list didn't change, then we don't need .New.
        if changed {
            let newStructure = out.map { $0.asMergedTreeNode() }
            result.structureState = MergeState.New(value: BookmarkTreeNode.Folder(guid: result.guid, children: newStructure))
            return
        }

        log.debug("Child list didn't change for \(result.guid). Keeping structure state \(result.structureState)")
    }

    private func resolveThreeWayValueConflict(guid: GUID) throws -> MergeState<BookmarkMirrorItem> {
        // TODO
        return try self.resolveTwoWayValueConflict(guid)
    }

    private func resolveTwoWayValueConflict(guid: GUID) throws -> MergeState<BookmarkMirrorItem> {
        // We don't check for all roots, because we might have to
        // copy them to the mirror or buffer, so we need to pick
        // a direction. The Places root is never uploaded.
        if BookmarkRoots.RootGUID == guid {
            log.debug("Two-way value merge on the root: always unaltered.")
            return MergeState.Unchanged
        }

        let localRecord = self.localItemSource.getLocalItemWithGUID(guid).value.successValue
        let remoteRecord = self.bufferItemSource.getBufferItemWithGUID(guid).value.successValue

        if let local = localRecord {
            if let remote = remoteRecord {
                // Two-way.
                log.debug("Comparing local (\(local.localModified)) to remote (\(remote.serverModified)) clock for two-way value merge of \(guid).")
                if local.localModified > remote.serverModified {
                    return MergeState.Local
                }
                return MergeState.Remote
            }

            // No remote!
            log.debug("Expected two-way merge for \(guid), but no remote item found.")
            return MergeState.Local
        }

        if let remote = remoteRecord {
            // No local!
            log.debug("Expected two-way merge for \(guid), but no local item found.")
            return MergeState.Remote
        }

        // Can't two-way merge with nothing!
        log.error("Expected two-way merge for \(guid), but no local or remote item found!")
        throw BookmarksMergeError()
    }

    // This will never be called with two primary .Unknown values.
    private func threeWayMerge(guid: GUID, localNode: BookmarkTreeNode, remoteNode: BookmarkTreeNode, mirrorNode: BookmarkTreeNode?) throws -> MergedTreeNode {
        if mirrorNode == nil {
            log.debug("Two-way merge for \(guid).")
        } else {
            log.debug("Three-way merge for \(guid).")
        }

        if remoteNode.isUnknown {
            if localNode.isUnknown {
                preconditionFailure("Two unknown nodes!")
            }

            log.debug("Taking local node in two/three-way merge: remote bafflingly unchanged.")
            // TODO: value-unchanged
            return MergedTreeNode.forLocal(localNode)
        }

        if localNode.isUnknown {
            log.debug("Taking remote node in two/three-way merge: local bafflingly unchanged.")
            // TODO: value-unchanged
            return MergedTreeNode.forRemote(remoteNode)
        }

        let result = MergedTreeNode(guid: guid, mirror: mirrorNode)
        result.local = localNode
        result.remote = remoteNode

        // Value merge. This applies regardless.
        if localNode.isUnknown {
            result.valueState = MergeState.Remote
        } else if remoteNode.isUnknown {
            result.valueState = MergeState.Local
        } else {
            if mirrorNode == nil {
                result.valueState = try self.resolveTwoWayValueConflict(guid)
            } else {
                result.valueState = try self.resolveThreeWayValueConflict(guid)
            }
        }

        switch localNode {
        case let .Folder(_, localChildren):
            if case let .Folder(_, remoteChildren) = remoteNode {
                // Structural merge.
                if localChildren.sameElements(remoteChildren, f: { $0.recordGUID == $1.recordGUID }) {
                    // Great!
                    log.debug("Local and remote records have same children in two-way merge.")
                    result.structureState = MergeState.New(value: localNode)    // TODO: what if it's the same as the mirror?
                    return result
                }

                // Merge the two folder lists.
                // We know that each side is internally consistent: that is, each
                // node in this list is present in the tree once only. But when we
                // combine the two lists, we might be inadvertently duplicating a
                // record that has already been, or will soon be, found in the other
                // tree. We need to be careful to make sure that we don't feature
                // a node in the tree more than once.
                // Remember to check deletions.
                log.debug("Local and remote records have different children. Merging.")

                // Assume it'll be the same as the remote one; mergeChildListsIntoMergedNode
                // sets this to New if the structure changes.
                result.structureState = MergeState.Remote
                try self.mergeChildListsIntoMergedNode(result, fromLocal: localNode, remote: remoteNode, mirror: mirrorNode)
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

    private func twoWayMerge(guid: GUID, localNode: BookmarkTreeNode, remoteNode: BookmarkTreeNode) throws -> MergedTreeNode {
        return try self.threeWayMerge(guid, localNode: localNode, remoteNode: remoteNode, mirrorNode: nil)
    }

    private func unchangedIf(out: MergedTreeNode, original: BookmarkMirrorItem?, new: BookmarkMirrorItem?) -> MergedTreeNode {
        guard let original = original, new = new else {
            return out
        }

        if new.sameAs(original) {
            out.valueState = MergeState.Unchanged
        }
        return out
    }

    private func takeLocalIfChanged(local: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) -> MergedTreeNode {
        let guid = local.recordGUID
        let localValues = self.localItemSource.getLocalItemWithGUID(guid).value.successValue
        let mirrorValues = self.mirrorItemSource.getMirrorItemWithGUID(guid).value.successValue

        // We don't expect these to ever fail to exist.
        assert(localValues != nil)

        let merged = MergedTreeNode.forLocal(local, mirror: mirror)
        return unchangedIf(merged, original: mirrorValues, new: localValues)
    }

    private func takeRemoteIfChanged(remote: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) -> MergedTreeNode {
        let guid = remote.recordGUID
        let remoteValues = self.bufferItemSource.getBufferItemWithGUID(guid).value.successValue
        let mirrorValues = self.mirrorItemSource.getMirrorItemWithGUID(guid).value.successValue

        assert(remoteValues != nil)

        let merged = MergedTreeNode.forRemote(remote, mirror: mirror)
        return unchangedIf(merged, original: mirrorValues, new: remoteValues)
    }

    // We'll end up looking at deletions and such as we go.
    // TODO: accumulate deletions into the three buckets as we go.
    func mergeNode(guid: GUID, localNode: BookmarkTreeNode?, mirrorNode: BookmarkTreeNode?, remoteNode: BookmarkTreeNode?) throws -> MergedTreeNode {
        log.debug("Merging nodes with GUID \(guid). Local match is \(localNode?.recordGUID).")

        // TODO: if the local node has a different GUID, it's because we did a value-based
        // merge. Make sure the local row with the differing local GUID doesn't
        // stick around.

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
        // This avoids repeated code in each conditional branch, and avoids the possibility of
        // certain moves causing us to hit the same node again.
        log.debug("Marking \(guid) as merged.")
        self.done.insert(guid)
        if let otherGUID = localNode?.recordGUID where otherGUID != guid {
            self.done.insert(otherGUID)
        }

        func takeRemoteAndMergeChildren(remote: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) throws -> MergedTreeNode {
            let merged = self.takeRemoteIfChanged(remote, mirror: mirror)
            if case .Folder = remote {
                log.debug("… and it's a folder. Taking remote children.")
                try self.oneWayMergeChildListsIntoMergedNode(merged, fromRemote: remote)
            }
            return merged
        }

        func takeLocalAndMergeChildren(local: BookmarkTreeNode, mirror: BookmarkTreeNode?=nil) throws -> MergedTreeNode {
            let merged = self.takeLocalIfChanged(local, mirror: mirror)
            if case .Folder = local {
                log.debug("… and it's a folder. Taking local children.")
                try self.oneWayMergeChildListsIntoMergedNode(merged, fromLocal: local)
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
                log.debug("Both local and remote changes to mirror item \(guid). Resolving conflict.")
                return try self.threeWayMerge(guid, localNode: loc, remoteNode: rem, mirrorNode: mirrorNode)
            }
            log.debug("Local-only change to mirror item \(guid).")
            return try takeLocalAndMergeChildren(loc, mirror: mirrorNode)
        }

        if let rem = remoteNode where !rem.isUnknown {
            log.debug("Remote-only change to mirror item \(guid).")
            return try takeRemoteAndMergeChildren(rem, mirror: mirrorNode)
        }

        log.debug("Record \(guid) didn't change from mirror.")
        return try takeMirrorNode(mirrorNode)
    }

    func merge() -> Deferred<Maybe<BookmarksMergeResult>> {
        return self.produceMergedTree()
          >>== self.produceMergeResultFromMergedTree
    }

    func produceMergeResultFromMergedTree(mergedTree: MergedTree) -> Deferred<Maybe<BookmarksMergeResult>> {
        let upstream = UpstreamCompletionOp()
        let buffer = BufferCompletionOp()
        let local = LocalOverrideCompletionOp()

        // TODO: walk the merged tree to produce filled ops.
        return deferMaybe(BookmarksMergeResult(uploadCompletion: upstream, overrideCompletion: local, bufferCompletion: buffer))
    }

    func produceMergedTree() -> Deferred<Maybe<MergedTree>> {
        // Don't ever do this work twice.
        if self.mergeAttempted {
            return deferMaybe(self.merged)
        }

        // Both local and remote should reach a single root when overlayed. If not, it means that
        // the tree is inconsistent -- there isn't a full tree present either on the server (or
        // local) or in the mirror, or the changes aren't congruent in some way. If we reach this
        // state, we cannot proceed.
        //
        // This is assert()ed in the initializer, too, so that we crash hard and early in developer
        // builds and tests.

        if !self.local.isFullyRootedIn(self.mirror) {
            log.warning("Local bookmarks not fully rooted when overlayed on mirror. This is most unusual.")
            return deferMaybe(BookmarksMergeErrorTreeIsUnrooted(roots: self.local.subtreeGUIDs))
        }

        if !self.remote.isFullyRootedIn(mirror) {
            log.warning("Remote bookmarks not fully rooted when overlayed on mirror. Partial read or write in buffer?")

            // This might be a temporary state: another client might not have uploaded all of its
            // records yet. Another batch might arrive in a second, or it might arrive a month
            // later if the user just closed the lid of their laptop and went on vacation!
            //
            // This can also be a semi-stable state; e.g., Bug 1235269. It's theoretically
            // possible for us to try to recover by requesting reupload from other devices
            // by changing syncID, or through some new command.
            //
            // Regardless, we can't proceed until this situation changes.
            return deferMaybe(BookmarksMergeErrorTreeIsUnrooted(roots: self.remote.subtreeGUIDs))
        }

        log.debug("Processing \(self.localAllGUIDs.count) local changes and \(self.remoteAllGUIDs.count) remote changes.")
        log.debug("\(self.local.subtrees.count) local subtrees and \(self.remote.subtrees.count) remote subtrees.")
        log.debug("Local is adding \(self.localAdditions.count) records, and remote is adding \(self.remoteAdditions.count).")

        if !conflictingGUIDs.isEmpty {
            log.warning("Expecting conflicts between local and remote: \(conflictingGUIDs.joinWithSeparator(", ")).")
        }

        // Pre-fetch items so we don't need to do async work later.
        return self.prefetchItems() >>> self.walkProducingMergedTree
    }

    private func prefetchItems() -> Success {
        // TODO: implement caching of results in the item source.
        return self.bufferItemSource.prefetchBufferItemsWithGUIDs(self.allChangedGUIDs)
           >>> { self.mirrorItemSource.prefetchMirrorItemsWithGUIDs(self.allChangedGUIDs) }
           >>> { self.localItemSource.prefetchLocalItemsWithGUIDs(self.allChangedGUIDs) }
    }

    // This should only be called once.
    // Callers should ensure validity of inputs.
    private func walkProducingMergedTree() -> Deferred<Maybe<MergedTree>> {
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

        self.mergeAttempted = true

        // Validate. Note that we might end up with *more* records than this -- records
        // that didn't change naturally aren't present in the change list on either side.
        let expected = self.allChangedGUIDs.subtract(self.allDeletions)
        assert(self.merged.allGUIDs.isSupersetOf(expected))
        assert(self.merged.allGUIDs.intersect(self.allDeletions).isEmpty)

        return deferMaybe(self.merged)
    }
}
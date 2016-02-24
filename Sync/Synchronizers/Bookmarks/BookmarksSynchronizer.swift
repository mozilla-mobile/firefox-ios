/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

typealias UploadFunction = ([Record<BookmarkBasePayload>], lastTimestamp: Timestamp?, onUpload: (POSTResult) -> DeferredTimestamp) -> DeferredTimestamp

class TrivialBookmarkStorer: BookmarkStorer {
    let uploader: UploadFunction
    init(uploader: UploadFunction) {
        self.uploader = uploader
    }

    func applyUpstreamCompletionOp(op: UpstreamCompletionOp, itemSources: ItemSources, trackingTimesInto local: LocalOverrideCompletionOp) -> Deferred<Maybe<POSTResult>> {
        log.debug("Uploading \(op.records.count) modified records.")
        log.debug("Uploading \(op.amendChildrenFromBuffer.count) amended buffer records.")
        log.debug("Uploading \(op.amendChildrenFromMirror.count) amended mirror records.")
        log.debug("Uploading \(op.amendChildrenFromLocal.count) amended local records.")

        var records: [Record<BookmarkBasePayload>] = []
        records.reserveCapacity(op.records.count + op.amendChildrenFromBuffer.count + op.amendChildrenFromLocal.count + op.amendChildrenFromMirror.count)
        records.appendContentsOf(op.records)

        func accumulateFromAmendMap(itemsWithNewChildren: [GUID: [GUID]], fetch: [GUID: [GUID]] -> Maybe<[GUID: BookmarkMirrorItem]>) throws /* MaybeErrorType */ {
            if itemsWithNewChildren.isEmpty {
                return
            }

            let fetched = fetch(itemsWithNewChildren)
            guard let items = fetched.successValue else {
                log.warning("Couldn't fetch items to amend.")
                throw fetched.failureValue!
            }

            items.forEach { (guid, item) in
                let payload = item.asPayloadWithChildren(itemsWithNewChildren[guid])
                let mappedGUID = payload["id"].asString ?? guid
                let record = Record<BookmarkBasePayload>(id: mappedGUID, payload: payload)
                records.append(record)
            }
        }

        do {
            try accumulateFromAmendMap(op.amendChildrenFromBuffer, fetch: { itemSources.buffer.getBufferItemsWithGUIDs($0.keys).value })
            try accumulateFromAmendMap(op.amendChildrenFromMirror, fetch: { itemSources.mirror.getMirrorItemsWithGUIDs($0.keys).value })
            try accumulateFromAmendMap(op.amendChildrenFromLocal, fetch: { itemSources.local.getLocalItemsWithGUIDs($0.keys).value })
        } catch {
            return deferMaybe(error as! MaybeErrorType)
        }

        var modified: Timestamp = 0
        var success: [GUID] = []
        var failed: [GUID: String] = [:]

        func onUpload(result: POSTResult) -> DeferredTimestamp {
            modified = result.modified
            success.appendContentsOf(result.success)
            result.failed.forEach { guid, message in
                failed[guid] = message
            }

            log.debug("Uploaded records got timestamp \(modified).")
            local.setModifiedTime(modified, guids: result.success)
            return deferMaybe(result.modified)
        }

        // Chain the last upload timestamp right into our lastFetched timestamp.
        // This is what Sync clients tend to do, but we can probably do better.
        // Upload 50 records at a time.
        return uploader(records, lastTimestamp: op.ifUnmodifiedSince, onUpload: onUpload)
            // As if we uploaded everything in one go.
            >>> { deferMaybe(POSTResult(modified: modified, success: success, failed: failed)) }
    }
}

// MARK: - External synchronizer interface.

public class BufferingBookmarksSynchronizer: TimestampedSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "bookmarks")
    }

    override var storageVersion: Int {
        return BookmarksStorageVersion
    }

    public func synchronizeBookmarksToStorage(storage: protocol<SyncableBookmarks, LocalItemSource, MirrorItemSource>, usingBuffer buffer: protocol<BookmarkBufferStorage, BufferItemSource>, withServer storageClient: Sync15StorageClient, info: InfoCollections, greenLight: () -> Bool) -> SyncResult {
        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(.NotStarted(reason))
        }

        let encoder = RecordEncoder<BookmarkBasePayload>(decode: BookmarkType.somePayloadFromJSON, encode: { $0 })

        guard let bookmarksClient = self.collectionClient(encoder, storageClient: storageClient) else {
            log.error("Couldn't make bookmarks factory.")
            return deferMaybe(FatalError(message: "Couldn't make bookmarks factory."))
        }

        let start = NSDate.nowMicroseconds()
        let mirrorer = BookmarksMirrorer(storage: buffer, client: bookmarksClient, basePrefs: self.prefs, collection: "bookmarks")
        let storer = TrivialBookmarkStorer(uploader: { records, lastTimestamp, onUpload in
            // Default to our last fetch time for If-Unmodified-Since.
            let timestamp = lastTimestamp ?? self.lastFetched
            return self.uploadRecords(records, by: 50, lastTimestamp: timestamp, storageClient: bookmarksClient, onUpload: onUpload)
              >>== effect(self.setTimestamp)
        })
        let applier = MergeApplier(buffer: buffer, storage: storage, client: storer, greenLight: greenLight)

        // TODO: if the mirrorer tells us we're incomplete, then don't bother trying to sync!
        // We will need to extend the BookmarksMirrorer interface to allow us to see what's
        // going on.
        let run = mirrorer.go(info, greenLight: greenLight)
              >>> applier.go
        run.upon { _ in
            let end = NSDate.nowMicroseconds()
            let duration = end - start
            log.info("Bookmark sync took \(duration)µs.")
        }
        return run
    }
}

class MergeApplier {
    let greenLight: () -> Bool
    let buffer: BookmarkBufferStorage
    let storage: SyncableBookmarks
    let client: BookmarkStorer
    let merger: BookmarksStorageMerger

    init(buffer: protocol<BookmarkBufferStorage, BufferItemSource>, storage: protocol<SyncableBookmarks, LocalItemSource, MirrorItemSource>, client: BookmarkStorer, greenLight: () -> Bool) {
        self.greenLight = greenLight
        self.buffer = buffer
        self.storage = storage
        self.merger = ThreeWayBookmarksStorageMerger(buffer: buffer, storage: storage)
        self.client = client
    }

    // Exposed for use from tests.
    func applyResult(result: BookmarksMergeResult) -> Success {
        return result.applyToClient(self.client, storage: self.storage, buffer: self.buffer)
    }

    func go() -> SyncResult {
        guard self.greenLight() else {
            log.info("Green light turned red; not merging bookmarks.")
            return deferMaybe(SyncStatus.Completed)
        }

        return self.merger.merge()
          >>== self.applyResult
           >>> always(SyncStatus.Completed)
    }
}

/**
 * The merger takes as input an existing storage state (mirror and local override),
 * a buffer of new incoming records that relate to the mirror, and performs a three-way
 * merge.
 *
 * The merge itself does not mutate storage. The result of the merge is conceptually a
 * tuple: a new mirror state, a set of reconciled + locally changed records to upload,
 * and two checklists of buffer and local state to discard.
 *
 * Typically the merge will be complete, resulting in a new mirror state, records to
 * upload, and completely emptied buffer and local. In the case of partial inconsistency
 * this will not be the case; incomplete subtrees will remain in the buffer. (We don't
 * expect local subtrees to ever be incomplete.)
 *
 * It is expected that the caller will immediately apply the result in this order:
 *
 * 1. Upload the remote changes, if any. If this fails we can retry the entire process.
 *
 * 2(a). Apply the local changes, if any. If this fails we will re-download the records
 *       we just uploaded, and should reach the same end state.
 *       This step takes a timestamp key from (1), because pushing a record into the mirror
 *       requires a server timestamp.
 *
 * 2(b). Switch to the new mirror state. If this fails, we should find that our reconciled
 *       server contents apply neatly to our mirror and empty local, and we'll reach the
 *       same end state.
 *       Mirror state is applied in a sane order to respect relational constraints:
 *
 *       - Add any new records in the value table.
 *       - Change any existing records in the value table.
 *       - Update structure.
 *       - Remove records from the value table.
 *
 * 3. Apply buffer changes. We only do this after the mirror has advanced; if we fail to
 *    clean up the buffer, it'll reconcile neatly with the mirror on a subsequent try.
 *
 * 4. Update bookkeeping timestamps. If this fails we will download uploaded records,
 *    find they match, and have no repeat merging work to do.
 *
 * The goal of merging is that the buffer is empty (because we reconciled conflicts and
 * updated the server), our local overlay is empty (because we reconciled conflicts and
 * applied our changes to the server), and the mirror matches the server.
 *
 * Note that upstream application is robust: we can use XIUS to ensure that writes don't
 * race. Buffer application is similarly robust, because this code owns all writes to the
 * buffer. Local and mirror application, however, is not: the user's actions can cause
 * changes to write to the database before we're done applying the results of a sync.
 * We mitigate this a little by being explicit about the local changes that we're flushing
 * (rather than, say, `DELETE FROM local`), but to do better we'd need change detection
 * (e.g., an in-memory monotonic counter) or locking to prevent bookmark operations from
 * racing. Later!
 */
protocol BookmarksStorageMerger: class {
    init(buffer: protocol<BookmarkBufferStorage, BufferItemSource>, storage: protocol<SyncableBookmarks, LocalItemSource, MirrorItemSource>)
    func merge() -> Deferred<Maybe<BookmarksMergeResult>>
}

class NoOpBookmarksMerger: BookmarksStorageMerger {
    let buffer: protocol<BookmarkBufferStorage, BufferItemSource>
    let storage: protocol<SyncableBookmarks, LocalItemSource, MirrorItemSource>

    required init(buffer: protocol<BookmarkBufferStorage, BufferItemSource>, storage: protocol<SyncableBookmarks, LocalItemSource, MirrorItemSource>) {
        self.buffer = buffer
        self.storage = storage
    }

    func merge() -> Deferred<Maybe<BookmarksMergeResult>> {
        return deferMaybe(BookmarksMergeResult.NoOp(ItemSources(local: self.storage, mirror: self.storage, buffer: self.buffer)))
    }
}

class ThreeWayBookmarksStorageMerger: BookmarksStorageMerger {
    let buffer: protocol<BookmarkBufferStorage, BufferItemSource>
    let storage: protocol<SyncableBookmarks, LocalItemSource, MirrorItemSource>

    required init(buffer: protocol<BookmarkBufferStorage, BufferItemSource>, storage: protocol<SyncableBookmarks, LocalItemSource, MirrorItemSource>) {
        self.buffer = buffer
        self.storage = storage
    }

    // MARK: - BookmarksStorageMerger.

    // Trivial one-way sync.
    private func applyLocalDirectlyToMirror() -> Deferred<Maybe<BookmarksMergeResult>> {
        // Theoretically, we do the following:
        // * Construct a virtual bookmark tree overlaying local on the mirror.
        // * Walk the tree to produce Sync records.
        // * Upload those records.
        // * Flatten that tree into the mirror, clearing local.
        //
        // This is simpler than a full three-way merge: it's tree delta then flatten.
        //
        // But we are confident that our local changes, when overlaid on the mirror, are
        // consistent. So we can take a little bit of a shortcut: process records
        // directly, rather than building a tree.
        //
        // So do the following:
        // * Take everything in `local` and turn it into a Sync record. This means pulling
        //   folder hierarchies out of localStructure, values out of local, and turning
        //   them into records. Do so in hierarchical order if we can, and set sortindex
        //   attributes to put folders first.
        // * Upload those records in as many batches as necessary. Ensure that each batch
        //   is consistent, if at all possible.
        // * Take everything in local that was successfully uploaded and move it into the
        //   mirror, using the timestamps we tracked from the upload.
        //
        // Optionally, set 'again' to true in our response, and do this work only for a
        // particular subtree (e.g., a single root, or a single branch of changes). This
        // allows us to make incremental progress.

        // TODO
        log.debug("No special-case local-only merging yet. Falling back to three-way merge.")
        return self.threeWayMerge()
    }

    private func applyIncomingDirectlyToMirror() -> Deferred<Maybe<BookmarksMergeResult>> {
        // If the incoming buffer is consistent -- and the result of the mirrorer
        // gives us a hint about that! -- then we can move the buffer records into
        // the mirror directly.
        //
        // Note that this is also true for entire subtrees: if none of the children
        // of, say, 'menu________' are modified locally, then we can apply it without
        // merging.
        //
        // TODO
        log.debug("No special-case remote-only merging yet. Falling back to three-way merge.")
        return self.threeWayMerge()
    }

    // This is exposed for testing.
    func getMerger() -> Deferred<Maybe<ThreeWayTreeMerger>> {
        return self.storage.treesForEdges() >>== { (local, remote) in
            if local.isEmpty && remote.isEmpty {
                // We should never have been called!
                return deferMaybe(BookmarksMergeError())
            }

            // Find the mirror tree so we can compare.
            return self.storage.treeForMirror() >>== { mirror in
                // At this point we know that there have been changes both locally and remotely.
                // (Or, in the general case, changes either locally or remotely.)

                let itemSources = ItemSources(local: CachingLocalItemSource(source: self.storage), mirror: CachingMirrorItemSource(source: self.storage), buffer: CachingBufferItemSource(source: self.buffer))
                return deferMaybe(ThreeWayTreeMerger(local: local, mirror: mirror, remote: remote, itemSources: itemSources))
            }
        }
    }

    func getMergedTree() -> Deferred<Maybe<MergedTree>> {
        return self.getMerger() >>== { $0.produceMergedTree() }
    }

    func threeWayMerge() -> Deferred<Maybe<BookmarksMergeResult>> {
        return self.getMerger() >>== { $0.produceMergedTree() >>== $0.produceMergeResultFromMergedTree }
    }

    func merge() -> Deferred<Maybe<BookmarksMergeResult>> {
        return self.buffer.isEmpty() >>== { noIncoming in

            // TODO: the presence of empty desktop roots in local storage
            // isn't something we really need to worry about. Can we skip it here?

            return self.storage.isUnchanged() >>== { noOutgoing in
                switch (noIncoming, noOutgoing) {
                case (true, true):
                    // Nothing to do!
                    return deferMaybe(BookmarksMergeResult.NoOp(ItemSources(local: self.storage, mirror: self.storage, buffer: self.buffer)))
                case (true, false):
                    // No incoming records to apply. Unilaterally apply local changes.
                    return self.applyLocalDirectlyToMirror()
                case (false, true):
                    // No outgoing changes. Unilaterally apply remote changes if they're consistent.
                    return self.buffer.validate() >>> self.applyIncomingDirectlyToMirror
                default:
                    // Changes on both sides. Merge.
                    return self.buffer.validate() >>> self.threeWayMerge
                }
            }
        }
    }
}
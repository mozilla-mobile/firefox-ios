/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

// MARK: - External synchronizer interface.

public class BufferingBookmarksSynchronizer: TimestampedSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "bookmarks")
    }

    override var storageVersion: Int {
        return BookmarksStorageVersion
    }

    public func synchronizeBookmarksToStorage(storage: SyncableBookmarks, usingBuffer buffer: BookmarkBufferStorage, withServer storageClient: Sync15StorageClient, info: InfoCollections, greenLight: () -> Bool) -> SyncResult {
        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(.NotStarted(reason))
        }

        let encoder = RecordEncoder<BookmarkBasePayload>(decode: BookmarkType.somePayloadFromJSON, encode: { $0 })

        guard let bookmarksClient = self.collectionClient(encoder, storageClient: storageClient) else {
            log.error("Couldn't make bookmarks factory.")
            return deferMaybe(FatalError(message: "Couldn't make bookmarks factory."))
        }

        let mirrorer = BookmarksMirrorer(storage: buffer, client: bookmarksClient, basePrefs: self.prefs, collection: "bookmarks")
        let applier = MergeApplier(buffer: buffer, storage: storage, client: bookmarksClient, greenLight: greenLight)

        // TODO: if the mirrorer tells us we're incomplete, then don't bother trying to sync!
        // We will need to extend the BookmarksMirrorer interface to allow us to see what's
        // going on.
        return mirrorer.go(info, greenLight: greenLight)
           >>> applier.go
    }
}

private class MergeApplier {
    let greenLight: () -> Bool
    let buffer: BookmarkBufferStorage
    let storage: SyncableBookmarks
    let client: Sync15CollectionClient<BookmarkBasePayload>
    let merger: BookmarksMerger

    init(buffer: BookmarkBufferStorage, storage: SyncableBookmarks, client: Sync15CollectionClient<BookmarkBasePayload>, greenLight: () -> Bool) {
        self.greenLight = greenLight
        self.buffer = buffer
        self.storage = storage
        self.merger = NoOpBookmarksMerger(buffer: buffer, storage: storage)
        self.client = client
    }

    func go() -> SyncResult {
        if !self.greenLight() {
            log.info("Green light turned red; not merging bookmarks.")
            return deferMaybe(SyncStatus.Completed)
        }

        return self.merger.merge() >>== { result in
            result.describe(log)
            return result.uploadCompletion.applyToClient(self.client)
              >>== { result.overrideCompletion.applyToStore(self.storage, withUpstreamResult: $0) }
               >>> { result.bufferCompletion.applyToBuffer(self.buffer) }
               >>> always(SyncStatus.Completed)
        }

    }
}

// MARK: - Self-description.

protocol DescriptionDestination {
    func write(message: String)
}

extension XCGLogger: DescriptionDestination {
    func write(message: String) {
        self.info(message)
    }
}

// MARK: - Protocols to define merge results.

protocol UpstreamCompletionOp {
    func describe(log: DescriptionDestination)

    // TODO: this should probably return a timestamp.
    // The XIUS that we'll need for the upload can be captured as part of the op.
    func applyToClient(client: Sync15CollectionClient<BookmarkBasePayload>) -> Deferred<Maybe<UploadResult>>
}

protocol LocalOverrideCompletionOp {
    func describe(log: DescriptionDestination)
    func applyToStore(storage: SyncableBookmarks, withUpstreamResult upstream: UploadResult) -> Success
}

protocol BufferCompletionOp {
    func describe(log: DescriptionDestination)
    func applyToBuffer(buffer: BookmarkBufferStorage) -> Success
}

struct BookmarksMergeResult {
    let uploadCompletion: UpstreamCompletionOp
    let overrideCompletion: LocalOverrideCompletionOp
    let bufferCompletion: BufferCompletionOp

    // If this is true, the merge was only partial, and you should try again immediately.
    // This allows for us to make progress on individual subtrees, without having huge
    // waterfall steps.
    let again: Bool

    func describe(log: DescriptionDestination) {
        log.write("Merge result:")
        self.uploadCompletion.describe(log)
        self.overrideCompletion.describe(log)
        self.bufferCompletion.describe(log)
        log.write("Again? \(again)")
    }

    static let NoOp = BookmarksMergeResult(uploadCompletion: UpstreamCompletionNoOp(), overrideCompletion: LocalOverrideCompletionNoOp(), bufferCompletion: BufferCompletionNoOp(), again: false)
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
 * 2(a). Apply the local changes, if any. If this fails we will re-download the records
 *       we just uploaded, and should reach the same end state.
 *       This step takes a timestamp key from (1), because pushing a record into the mirror
 *       requires a server timestamp.
 * 2(b). Switch to the new mirror state. If this fails, we should find that our reconciled
 *       server contents apply neatly to our mirror and empty local, and we'll reach the
 *       same end state.
 * 3. Apply buffer changes. We only do this after the mirror has advanced; if we fail to
 *    clean up the buffer, it'll reconcile neatly with the mirror on a subsequent try.
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
protocol BookmarksMerger {
    init(buffer: BookmarkBufferStorage, storage: SyncableBookmarks)
    func merge() -> Deferred<Maybe<BookmarksMergeResult>>
}

// MARK: - No-op implementations of each protocol.

typealias UploadResult = (succeeded: [GUID: Timestamp], failed: Set<GUID>)

class NoOpBookmarksMerger: BookmarksMerger {
    let buffer: BookmarkBufferStorage
    let storage: SyncableBookmarks

    required init(buffer: BookmarkBufferStorage, storage: SyncableBookmarks) {
        self.buffer = buffer
        self.storage = storage
    }

    func merge() -> Deferred<Maybe<BookmarksMergeResult>> {
        return deferMaybe(BookmarksMergeResult.NoOp)
    }
}

class UpstreamCompletionNoOp: UpstreamCompletionOp {
    func describe(log: DescriptionDestination) {
        log.write("No upstream operation.")
    }

    func applyToClient(client: Sync15CollectionClient<BookmarkBasePayload>) -> Deferred<Maybe<UploadResult>> {
        return deferMaybe((succeeded: [:], failed: Set<GUID>()))
    }
}

class LocalOverrideCompletionNoOp: LocalOverrideCompletionOp {
    func describe(log: DescriptionDestination) {
        log.write("No local override operation.")
    }

    func applyToStore(storage: SyncableBookmarks, withUpstreamResult upstream: UploadResult) -> Success {
        return succeed()
    }
}

class BufferCompletionNoOp: BufferCompletionOp {
    func describe(log: DescriptionDestination) {
        log.write("No buffer operation.")
    }
    func applyToBuffer(buffer: BookmarkBufferStorage) -> Success {
        return succeed()
    }
}

// MARK: - Real implementations of each protocol.

class TrivialBookmarksMerger: BookmarksMerger {
    let buffer: BookmarkBufferStorage
    let storage: SyncableBookmarks

    required init(buffer: BookmarkBufferStorage, storage: SyncableBookmarks) {
        self.buffer = buffer
        self.storage = storage
    }

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

    private func threeWayMerge() -> Deferred<Maybe<BookmarksMergeResult>> {
        // At this point we know that there have been changes both locally and remotely.
        // It's very likely that there's almost no overlap, and thus no real conflicts to
        // resolve -- a three-way merge isn't always a bad thing -- but we won't know until
        // we compare records.
        //
        // Even though this function is called `threeWayMerge`, it also handles the case
        // of a two-way merge (one without a shared parent; for the roots, this will only
        // be on a first sync): content-based and structural merging is needed at all
        // layers of the hierarchy, so we simply generalize that to also apply to roots.
        //
        // In a sense, a two-way merge is solved by constructing a shared parent consisting of
        // only the Places root. (Special care must be taken to not deduce that one side has
        // deleted a root, of course, as would be the case of a Sync server that doesn't contain
        // a Mobile Bookmarks folder -- the set of roots can only grow, not shrink.)

        // TODO
        return deferMaybe(BookmarksMergeResult.NoOp)
    }

    func merge() -> Deferred<Maybe<BookmarksMergeResult>> {
        return self.buffer.isEmpty() >>== { noIncoming in

            // TODO: the presence of empty desktop roots in local storage
            // isn't something we really need to worry about. Can we skip it here?

            return self.storage.isUnchanged() >>== { noOutgoing in
                switch (noIncoming, noOutgoing) {
                case (true, true):
                    // Nothing to do!
                    return deferMaybe(BookmarksMergeResult.NoOp)
                case (true, false):
                    // No incoming records to apply. Unilaterally apply local changes.
                    return self.applyLocalDirectlyToMirror()
                case (false, true):
                    // No outgoing changes. Unilaterally apply remote changes if they're consistent.
                    return self.applyIncomingDirectlyToMirror()
                default:
                    // Changes on both sides. Merge.
                    return self.threeWayMerge()
                }
            }
        }
    }
}
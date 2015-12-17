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
        // TODO
        return deferMaybe(BookmarksMergeResult.NoOp)
    }

    private func applyIncomingDirectlyToMirror() -> Deferred<Maybe<BookmarksMergeResult>> {
        // TODO
        return deferMaybe(BookmarksMergeResult.NoOp)
    }

    private func threeWayMerge() -> Deferred<Maybe<BookmarksMergeResult>> {
        // TODO
        return deferMaybe(BookmarksMergeResult.NoOp)
    }

    func merge() -> Deferred<Maybe<BookmarksMergeResult>> {
        return self.buffer.isEmpty() >>== { noIncoming in
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
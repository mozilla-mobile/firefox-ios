/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

private let log = Logger.syncLogger

public class BufferingBookmarksSynchronizer: TimestampedSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "bookmarks")
    }

    override var storageVersion: Int {
        return BookmarksStorageVersion
    }

    public func mirrorBookmarksToStorage(storage: BookmarkBufferStorage, withServer storageClient: Sync15StorageClient, info: InfoCollections, greenLight: () -> Bool) -> SyncResult {
        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(.NotStarted(reason))
        }

        let encoder = RecordEncoder<BookmarkBasePayload>(decode: BookmarkType.somePayloadFromJSON, encode: { $0 })

        guard let bookmarksClient = self.collectionClient(encoder, storageClient: storageClient) else {
            log.error("Couldn't make bookmarks factory.")
            return deferMaybe(FatalError(message: "Couldn't make bookmarks factory."))
        }

        let mirrorer = BookmarksMirrorer(storage: storage, client: bookmarksClient, basePrefs: self.prefs, collection: "bookmarks")
        return mirrorer.go(info, greenLight: greenLight) >>> always(SyncStatus.Completed)
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
 * 2. Apply the local changes, if any. If this fails we will re-download the records
 *    we just uploaded, and should reach the same end state.
 * 3. Switch to the new mirror state. If this fails, we should find that our reconciled
 *    server contents apply neatly to our mirror and empty local, and we'll reach the
 *    same end state.
 * 4. Update bookkeeping timestamps. If this fails we will download uploaded records,
 *    find they match, and have no repeat merging work to do.
 *
 * The goal of merging is that the buffer is empty (because we reconciled conflicts and
 * updated the server), our local overlay is empty (because we reconciled conflicts and
 * applied our changes to the server), and the mirror matches the server.
 *
 * This implementation is coupled to SQLiteBookmarks out of convenience.
 */
class SQLiteBookmarksMerger {
    private let buffer: BookmarkBufferStorage
    private let storage: SQLiteBookmarks

    init(buffer: BookmarkBufferStorage, storage: SQLiteBookmarks) {
        self.buffer = buffer
        self.storage = storage
    }
}
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger

typealias UploadFunction = ([Record<BookmarkBasePayload>], _ lastTimestamp: Timestamp?, _ onUpload: @escaping (POSTResult, Timestamp?) -> DeferredTimestamp) -> DeferredTimestamp

class TrivialBookmarkStorer: BookmarkStorer {
    let uploader: UploadFunction
    init(uploader: @escaping UploadFunction) {
        self.uploader = uploader
    }

    func applyUpstreamCompletionOp(_ op: UpstreamCompletionOp, itemSources: ItemSources, trackingTimesInto local: LocalOverrideCompletionOp) -> Deferred<Maybe<POSTResult>> {
        log.debug("Uploading \(op.records.count) modified records.")
        log.debug("Uploading \(op.amendChildrenFromBuffer.count) amended buffer records.")
        log.debug("Uploading \(op.amendChildrenFromMirror.count) amended mirror records.")
        log.debug("Uploading \(op.amendChildrenFromLocal.count) amended local records.")

        var records: [Record<BookmarkBasePayload>] = []
        records.reserveCapacity(op.records.count + op.amendChildrenFromBuffer.count + op.amendChildrenFromLocal.count + op.amendChildrenFromMirror.count)
        records.append(contentsOf: op.records)

        func accumulateFromAmendMap(_ itemsWithNewChildren: [GUID: [GUID]], fetch: ([GUID: [GUID]]) -> Maybe<[GUID: BookmarkMirrorItem]>) throws /* MaybeErrorType */ {
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
                let mappedGUID = payload["id"].string ?? guid
                let record = Record<BookmarkBasePayload>(id: mappedGUID, payload: payload)
                records.append(record)
            }
        }

        do {
            try accumulateFromAmendMap(op.amendChildrenFromBuffer, fetch: { itemSources.buffer.getBufferItemsWithGUIDs($0.keys).value })
            try accumulateFromAmendMap(op.amendChildrenFromMirror, fetch: { itemSources.mirror.getMirrorItemsWithGUIDs($0.keys).value })
            try accumulateFromAmendMap(op.amendChildrenFromLocal, fetch: { itemSources.local.getLocalItemsWithGUIDs($0.keys).value })
        } catch {
            return deferMaybe(error as MaybeErrorType)
        }

        var success: [GUID] = []
        var failed: [GUID: String] = [:]

        func onUpload(_ result: POSTResult, lastModified: Timestamp?) -> DeferredTimestamp {
            success.append(contentsOf: result.success)
            result.failed.forEach { guid, message in
                failed[guid] = message
            }

            log.debug("Uploaded records got timestamp \(lastModified ??? "nil").")
            let modified = lastModified ?? 0
            local.setModifiedTime(modified, guids: result.success)
            return deferMaybe(modified)
        }

        // Chain the last upload timestamp right into our lastFetched timestamp.
        // This is what Sync clients tend to do, but we can probably do better.
        return uploader(records, op.ifUnmodifiedSince, onUpload)
            // As if we uploaded everything in one go.
            >>> { deferMaybe(POSTResult(success: success, failed: failed)) }
    }
}

open class MalformedRecordError: MaybeErrorType, SyncPingFailureFormattable {
    open var description: String {
        return "Malformed record."
    }
    open var failureReasonName: SyncPingFailureReasonName {
        return .otherError
    }
}

// MARK: - External synchronizer interface.

open class BufferingBookmarksSynchronizer: TimestampedSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs, why: SyncReason) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, why: why, collection: "bookmarks")
    }

    override var storageVersion: Int {
        return BookmarksStorageVersion
    }

    fileprivate func buildMobileRootRecord(_ local: LocalItemSource, _ buffer: BufferItemSource, additionalChildren: [BookmarkMirrorItem], deletedChildren: [GUID]) -> Deferred<Maybe<Record<BookmarkBasePayload>>> {
        let newBookmarkGUIDs = additionalChildren.map { $0.guid }
        return buffer.getBufferItemWithGUID(BookmarkRoots.MobileFolderGUID).bind { maybeMobileRoot in
            // Update (or create!) the Mobile Root folder with its new children.
            if let mobileRoot = maybeMobileRoot.successValue {
                return buffer.getBufferChildrenGUIDsForParent(mobileRoot.guid)
                    .map { $0.map({ (mobileRoot: mobileRoot, children: $0.filter { !deletedChildren.contains($0) } + newBookmarkGUIDs) }) }
            } else {
                return local.getLocalItemWithGUID(BookmarkRoots.MobileFolderGUID)
                    .map { $0.map({ (mobileRoot: $0, children: newBookmarkGUIDs) }) }
            }
        } >>== { (mobileRoot: BookmarkMirrorItem, children: [GUID]) in
            let payload = mobileRoot.asPayloadWithChildren(children)
            guard let mappedGUID = payload["id"].string else {
                return deferMaybe(MalformedRecordError())
            }
            return deferMaybe(Record<BookmarkBasePayload>(id: mappedGUID, payload: payload))
        }
    }

    func buildMobileRootAndChildrenRecords(_ local: LocalItemSource, _ buffer: BufferItemSource, additionalChildren: [BookmarkMirrorItem], deletedChildren: [GUID]) -> Deferred<Maybe<(mobileRootRecord: Record<BookmarkBasePayload>, childrenRecords: [Record<BookmarkBasePayload>])>> {
        let childrenRecords =
        additionalChildren.map { bkm -> Record<BookmarkBasePayload> in
            let payload = bkm.asPayload()
            let mappedGUID = payload["id"].string ?? bkm.guid
            return Record<BookmarkBasePayload>(id: mappedGUID, payload: payload)
        } +
        deletedChildren.map { guid -> Record<BookmarkBasePayload> in
            let payload = BookmarkBasePayload.deletedPayload(guid)
            let mappedGUID = payload["id"].string ?? guid
            return Record<BookmarkBasePayload>(id: mappedGUID, payload: payload)
        }

        return self.buildMobileRootRecord(local, buffer, additionalChildren: additionalChildren, deletedChildren: deletedChildren) >>== { mobileRootRecord in
            return deferMaybe((mobileRootRecord: mobileRootRecord, childrenRecords: childrenRecords))
        }
    }

    func uploadSomeLocalRecords(_ storage: SyncableBookmarks & LocalItemSource & MirrorItemSource, _ mirrorer: BookmarksMirrorer, _ bookmarksClient: Sync15CollectionClient<BookmarkBasePayload>, mobileRootRecord: Record<BookmarkBasePayload>, childrenRecords: [Record<BookmarkBasePayload>]) -> Success {
        var newBookmarkGUIDs: [GUID] = []
        var deletedBookmarksGUIDs: [GUID] = []
        for record in childrenRecords {
            // No mutable l-values in Swift :(
            if record.payload.deleted {
                deletedBookmarksGUIDs.append(record.id)
            } else {
                newBookmarkGUIDs.append(record.id)
            }
        }
        let records = [mobileRootRecord] + childrenRecords
        return self.uploadRecordsSingleBatch(records, lastTimestamp: mirrorer.lastModified, storageClient: bookmarksClient) >>== { (timestamp: Timestamp, succeeded: [GUID]) -> Success in

            let bufferValuesToMoveFromLocal = Set(newBookmarkGUIDs).intersection(Set(succeeded))
            let deletedValues = Set(deletedBookmarksGUIDs).intersection(Set(succeeded))
            let mobileRoot = (mobileRootRecord.payload as MirrorItemable).toMirrorItem(timestamp)
            let bufferOP = BufferUpdatedCompletionOp(bufferValuesToMoveFromLocal: bufferValuesToMoveFromLocal, deletedValues: deletedValues, mobileRoot: mobileRoot, modifiedTime: timestamp)
            return storage.applyBufferUpdatedCompletionOp(bufferOP) >>> {
                mirrorer.advanceNextDownloadTimestampTo(timestamp: timestamp) // We need to advance our batching downloader timestamp to match. See Bug 1253458.
                return succeed()
            }
        }
    }

    open func synchronizeBookmarksToStorage(_ storage: SyncableBookmarks & LocalItemSource & MirrorItemSource, usingBuffer buffer: BookmarkBufferStorage & BufferItemSource, withServer storageClient: Sync15StorageClient, info: InfoCollections, greenLight: @escaping () -> Bool, remoteClientsAndTabs: RemoteClientsAndTabs) -> SyncResult {
        if self.prefs.boolForKey("dateAddedMigrationDone") != true {
            self.lastFetched = 0
            self.prefs.setBool(true, forKey: "dateAddedMigrationDone")
        }

        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(.notStarted(reason))
        }

        let encoder = RecordEncoder<BookmarkBasePayload>(decode: BookmarkType.somePayloadFromJSON, encode: { $0.json })

        guard let bookmarksClient = self.collectionClient(encoder, storageClient: storageClient) else {
            log.error("Couldn't make bookmarks factory.")
            return deferMaybe(FatalError(message: "Couldn't make bookmarks factory."))
        }

        let start = Date.nowMicroseconds()
        let mirrorer = BookmarksMirrorer(storage: buffer, client: bookmarksClient, basePrefs: self.prefs, collection: "bookmarks", statsSession: self.statsSession)
        let storer = TrivialBookmarkStorer(uploader: { records, lastTimestamp, onUpload in
            let timestamp = lastTimestamp ?? self.lastFetched
            return self.uploadRecords(records, lastTimestamp: timestamp, storageClient: bookmarksClient, onUpload: onUpload)
              >>== effect { timestamp in
                // We need to advance our batching downloader timestamp to match. See Bug 1253458.
                self.setTimestamp(timestamp)
                mirrorer.advanceNextDownloadTimestampTo(timestamp: timestamp)
            }
        })

        statsSession.start()
        
        let doMirror = mirrorer.go(info: info, greenLight: greenLight)
        let run: SyncResult

        if !AppConstants.shouldMergeBookmarks {
            run = doMirror >>== { result -> SyncResult in
                // Validate the buffer to report statistics.
                if case .completed = result {
                    log.debug("Validating completed buffer download.")
                    return buffer.validate().bind { validationResult in
                        guard let invalidError = validationResult.failureValue as? BufferInvalidError else {
                            return deferMaybe(result)
                        }
                        return buffer.getUpstreamRecordCount().bind { checked -> Success in
                            self.statsSession.validationStats = self.validationStatsFrom(error: invalidError, checked: checked)
                            return self.maybeStartRepairProcedure(greenLight: greenLight, error: invalidError, remoteClientsAndTabs: remoteClientsAndTabs)
                        } >>> {
                            return deferMaybe(result)
                        }
                    }
                }
                return deferMaybe(result)
            } >>== { result in
                guard AppConstants.MOZ_SIMPLE_BOOKMARKS_SYNCING else {
                    return deferMaybe(result)
                }
                guard case .completed = result else {
                    return deferMaybe(result)
                }

                // -1 because we also need to upload the mobile root.
                return (storage.getLocalBookmarksModifications(limit: bookmarksClient.maxBatchPostRecords - 1) >>== { (deletedGUIDs, newBookmarks) -> Success in
                    guard newBookmarks.count > 0 || deletedGUIDs.count > 0 else {
                        return succeed()
                    }
                    return self.buildMobileRootAndChildrenRecords(storage, buffer, additionalChildren: newBookmarks, deletedChildren: deletedGUIDs) >>== { (mobileRootRecord, childrenRecords) in
                        return self.uploadSomeLocalRecords(storage, mirrorer, bookmarksClient, mobileRootRecord: mobileRootRecord, childrenRecords: childrenRecords)
                    }
                }).bind { simpleSyncingResult in
                    if let failure = simpleSyncingResult.failureValue {
                        let description = failure is RecordTooLargeError ? "Record too large" : failure.description
                        Sentry.shared.send(message: "Failed to simple sync bookmarks", tag: SentryTag.bookmarks, severity: .error, description: description)
                    }
                    return deferMaybe(result)
                }
            }
        } else {
            run = doMirror >>== { result in
                // Only bother trying to sync if the mirror operation wasn't interrupted or partial.
                if case .completed = result {
                    return buffer.validate().bind { result in
                        if let invalidError = result.failureValue as? BufferInvalidError {
                            return buffer.getUpstreamRecordCount().bind { checked in
                                self.statsSession.validationStats = self.validationStatsFrom(error: invalidError, checked: checked)
                                return self.maybeStartRepairProcedure(greenLight: greenLight, error: invalidError, remoteClientsAndTabs: remoteClientsAndTabs) >>> {
                                    return deferMaybe(invalidError)
                                }
                            }
                        }
                        
                        let applier = MergeApplier(buffer: buffer, storage: storage, client: storer, statsSession: self.statsSession, greenLight: greenLight)
                        return applier.go()
                    }
                }
                return deferMaybe(result)
            }
        }

        run.upon { result in
            let end = Date.nowMicroseconds()
            let duration = end - start
            log.info("Bookmark \(AppConstants.shouldMergeBookmarks ? "sync" : "mirroring") took \(duration)µs. Result was \(result.successValue?.description ?? result.failureValue?.description ?? "failure")")
        }

        return run
    }

    private func validationStatsFrom(error: BufferInvalidError, checked: Int?) -> ValidationStats {
        let problems = error.inconsistencies.map { ValidationProblem(name: $0.trackingEvent, count: $1.count) }
        return ValidationStats(problems: problems, took: error.validationDuration, checked: checked)
    }

    private func maybeStartRepairProcedure(greenLight: () -> Bool, error: BufferInvalidError, remoteClientsAndTabs: RemoteClientsAndTabs) -> Success {
        guard AppConstants.MOZ_BOOKMARKS_REPAIR_REQUEST && greenLight() else {
            return succeed()
        }
        log.warning("Buffer inconsistent, starting repair procedure")
        let repairer = BookmarksRepairRequestor(scratchpad: self.scratchpad, basePrefs: self.basePrefs, remoteClients: remoteClientsAndTabs)
        return repairer.startRepairs(validationInfo: error.inconsistencies).bind { result in
            if let repairFailure = result.failureValue {
                Sentry.shared.send(message: "Bookmarks repair failure", tag: SentryTag.bookmarks, severity: .error, description: repairFailure.description)
            } else {
                Sentry.shared.send(message: "Bookmarks repair succeeded", tag: SentryTag.bookmarks, severity: .debug)
            }
            return succeed()
        }
    }
}

class MergeApplier {
    let greenLight: () -> Bool
    let buffer: BookmarkBufferStorage
    let storage: SyncableBookmarks
    let client: BookmarkStorer
    let merger: BookmarksStorageMerger
    let statsSession: SyncEngineStatsSession

    init(buffer: BookmarkBufferStorage & BufferItemSource, storage: SyncableBookmarks & LocalItemSource & MirrorItemSource, client: BookmarkStorer, statsSession: SyncEngineStatsSession, greenLight: @escaping () -> Bool) {
        self.greenLight = greenLight
        self.buffer = buffer
        self.storage = storage
        self.merger = ThreeWayBookmarksStorageMerger(buffer: buffer, storage: storage)
        self.client = client
        self.statsSession = statsSession
    }

    // Exposed for use from tests.
    func applyResult(_ result: BookmarksMergeResult) -> Success {
        return result.applyToClient(self.client, storage: self.storage, buffer: self.buffer)
    }

    func go() -> SyncResult {
        guard self.greenLight() else {
            log.info("Green light turned red; not merging bookmarks.")
            return deferMaybe(SyncStatus.completed(statsSession.end()))
        }

        return self.merger.merge()
          >>== self.applyResult
           >>> always(SyncStatus.completed(statsSession.end()))
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
 *
 *       Mirror state is applied in a sane order to respect relational constraints, even though
 *       we configure sqlite to defer constraint validation until the transaction is committed.
 *       That means:
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
    init(buffer: BookmarkBufferStorage & BufferItemSource, storage: SyncableBookmarks & LocalItemSource & MirrorItemSource)
    func merge() -> Deferred<Maybe<BookmarksMergeResult>>
}

class NoOpBookmarksMerger: BookmarksStorageMerger {
    let buffer: BookmarkBufferStorage & BufferItemSource
    let storage: SyncableBookmarks & LocalItemSource & MirrorItemSource

    required init(buffer: BookmarkBufferStorage & BufferItemSource, storage: SyncableBookmarks & LocalItemSource & MirrorItemSource) {
        self.buffer = buffer
        self.storage = storage
    }

    func merge() -> Deferred<Maybe<BookmarksMergeResult>> {
        return deferMaybe(BookmarksMergeResult.NoOp(ItemSources(local: self.storage, mirror: self.storage, buffer: self.buffer)))
    }
}

class ThreeWayBookmarksStorageMerger: BookmarksStorageMerger {
    let buffer: BookmarkBufferStorage & BufferItemSource
    let storage: SyncableBookmarks & LocalItemSource & MirrorItemSource

    required init(buffer: BookmarkBufferStorage & BufferItemSource, storage: SyncableBookmarks & LocalItemSource & MirrorItemSource) {
        self.buffer = buffer
        self.storage = storage
    }

    // MARK: - BookmarksStorageMerger.

    // Trivial one-way sync.
    fileprivate func applyLocalDirectlyToMirror() -> Deferred<Maybe<BookmarksMergeResult>> {
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
        // * Upload those records in as few batches as possible. Ensure that each batch
        //   is consistent, if at all possible, though we're hoping for server support for
        //   atomic writes.
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

    fileprivate func applyIncomingDirectlyToMirror() -> Deferred<Maybe<BookmarksMergeResult>> {
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
            // At this point *might* have two empty trees. This should only be the case if
            // there are value-only changes (e.g., a renamed bookmark).
            // We don't fail in that case, but we could optimize here.

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
                    log.debug("No incoming and no outgoing records: no-op.")
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

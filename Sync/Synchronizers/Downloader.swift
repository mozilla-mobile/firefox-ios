/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.syncLogger

class BatchingDownloader<T: CleartextPayloadJSON> {
    let client: Sync15CollectionClient<T>
    let collection: String
    let prefs: Prefs
    let batchingState: BatchingStateMachine

    var batch: [Record<T>] = []

    func store(_ records: [Record<T>]) {
        self.batch += records
    }

    func retrieve() -> [Record<T>] {
        let ret = self.batch
        self.batch = []
        return ret
    }

    var _advance: (() -> Void)?
    func advance() {
        guard let f = self._advance else {
            return
        }
        self._advance = nil
        f()
    }

    init(collectionClient: Sync15CollectionClient<T>, basePrefs: Prefs, collection: String) {
        self.client = collectionClient
        self.collection = collection
        let branchName = "downloader." + collection + "."
        self.prefs = basePrefs.branch(branchName)
        self.batchingState = BatchingStateMachine(prefs: self.prefs)

        log.info("Downloader configured with prefs '\(self.prefs.getBranchPrefix())'.")
    }

    static func resetDownloaderWithPrefs(_ basePrefs: Prefs, collection: String) {
        // This leads to stupid paths like 'profile.sync.synchronizer.history..downloader.history..'.
        // Sorry, but it's out in the world now...
        let branchName = "downloader." + collection + "."
        let prefs = basePrefs.branch(branchName)

        let lm = prefs.timestampForKey("lastModified")
        let bt = prefs.timestampForKey("baseTimestamp")
        log.debug("Resetting downloader prefs \(prefs.getBranchPrefix()). Previous values: \(lm ??? "nil"), \(bt ??? "nil").")

        prefs.removeObjectForKey("nextOffset")
        prefs.removeObjectForKey("offsetNewer")
        prefs.removeObjectForKey("baseTimestamp")
        prefs.removeObjectForKey("lastModified")

        BatchingStateMachine.resetFromPrefs(prefs)
    }

    /**
     * Clients should provide the same set of parameters alongside an `offset` as was
     * provided with the initial request. The only thing that varies in our batch fetches
     * is `newer`, so we track the original value alongside.
     */
    var nextFetchParameters: (String, Timestamp)? {
        get {
            let o = self.prefs.stringForKey("nextOffset")
            let n = self.prefs.timestampForKey("offsetNewer")
            guard let offset = o, let newer = n else {
                return nil
            }
            return (offset, newer)
        }
        set (value) {
            if let (offset, newer) = value {
                self.prefs.setString(offset, forKey: "nextOffset")
                self.prefs.setTimestamp(newer, forKey: "offsetNewer")
            } else {
                self.prefs.removeObjectForKey("nextOffset")
                self.prefs.removeObjectForKey("offsetNewer")
            }
        }
    }

    // Set after each batch, from record timestamps.
    var baseTimestamp: Timestamp {
        get {
            return self.prefs.timestampForKey("baseTimestamp") ?? Date.now()
        }
        set (value) {
            self.prefs.setTimestamp(value, forKey: "baseTimestamp")
        }
    }

    // Only set at the end of a batch, from headers.
    var lastModified: Timestamp {
        get {
            return self.prefs.timestampForKey("lastModified") ?? 0
        }
        set (value) {
            self.prefs.setTimestamp(value, forKey: "lastModified")
        }
    }

    /**
     * Call this when a significant structural server change has been detected.
     */
    func reset() -> Success {
        self.baseTimestamp = 0
        self.lastModified = 0
        self.nextFetchParameters = nil
        self.batch = []
        self._advance = nil
        self.batchingState.reset()
        return succeed()
    }

    func go(_ info: InfoCollections, limit: Int) -> Deferred<Maybe<DownloadEndState>> {
        guard let modified = info.modified(self.collection) else {
            log.debug("No server modified time for collection \(self.collection).")
            return deferMaybe(.noNewData)
        }

        log.debug("Modified: \(modified); last \(self.lastModified).")
        if modified == self.lastModified {
            log.debug("No more data to batch-download.")
            return deferMaybe(.noNewData)
        }

        // If the caller hasn't advanced after the last batch, strange things will happen --
        // potentially looping indefinitely. Warn.
        if self._advance != nil && !self.batch.isEmpty {
            log.warning("Downloading another batch without having advanced. This might be a bug.")
        }
        return self.downloadNextBatchWithLimit(limit, infoModified: modified)
    }

    func advanceTimestampTo(_ timestamp: Timestamp) {
        log.debug("Advancing downloader lastModified from \(self.lastModified) to \(timestamp).")
        self.lastModified = timestamp
    }

    // We're either fetching from our current base timestamp with no offset,
    // or the timestamp we were using when we last saved an offset.
    func fetchParameters() -> (String?, Timestamp) {
        if let (offset, since) = self.nextFetchParameters {
            return (offset, since)
        }
        return (nil, max(self.lastModified, self.baseTimestamp))
    }

    func downloadNextBatchWithLimit(_ limit: Int, infoModified: Timestamp) -> Deferred<Maybe<DownloadEndState>> {
        let (offset, since) = self.fetchParameters()
        log.debug("Fetching newer=\(since), offset=\(offset ?? "nil").")

        let (sort, direction) = batchingState.fetchingParameters
        let fetch = self.client.getSince(since, sort: sort, limit: limit, offset: offset, directionQuery: direction)

        func handleFailure(_ err: MaybeErrorType) -> Deferred<Maybe<DownloadEndState>> {
            log.debug("Handling failure.")
            guard let badRequest = err as? BadRequestError<[Record<T>]>, badRequest.response.metadata.status == 412 else {
                // Just pass through the failure.
                return deferMaybe(err)
            }

            // Conflict. Start again.
            log.warning("Server contents changed during offset-based batching. Stepping back.")
            self.nextFetchParameters = nil
            return deferMaybe(.interrupted)
        }

        func handleSuccess(_ response: StorageResponse<[Record<T>]>) -> Deferred<Maybe<DownloadEndState>> {
            log.debug("Handling success.")
            let nextOffset = response.metadata.nextOffset
            let responseModified = response.value.last?.modified

            // Queue up our metadata advance. We wait until the consumer has fetched
            // and processed this batch; they'll call .advance() on success.
            self._advance = {
                self.batchingState.advance()

                // Shift to the next offset. This might be nil, in which case… fine!
                // Note that we preserve the previous 'newer' value from the offset or the original fetch,
                // even as we update baseTimestamp.
                self.nextFetchParameters = nextOffset == nil ? nil : (nextOffset!, since)

                // If there are records, advance to just before the timestamp of the last.
                // If our next fetch with X-Weave-Next-Offset fails, at least we'll start here.
                if let newBase = responseModified {
                    // The base timestamp we use depends on what state we're in.
                    var newBaseTimestamp: Timestamp
                    switch self.batchingState.current {
                    // To get the most recent we'll need to provide an up-to-date timestamp.
                    case .mostRecentSet: newBaseTimestamp = Date.now()
                    // To get the oldest, we need to make sure we start from 0.
                    case .oldestSet: newBaseTimestamp = 0
                    /// When backfilling, business as usual - step forwards as per the response modified time.
                    case .backfillFromOldest: newBaseTimestamp = newBase - 1
                    }
                    
                    log.debug("Advancing baseTimestamp to \(newBase)")
                    self.baseTimestamp = newBaseTimestamp
                }

                if nextOffset == nil {
                    // If we can't get a timestamp from the header -- and we should always be able to --
                    // we fall back on the collection modified time in i/c, as supplied by the caller.
                    // In any case where there is no racing writer these two values should be the same.
                    // If they differ, the header should be later. If it's missing, and we use the i/c
                    // value, we'll simply redownload some records.
                    // All bets are off if we hit this case and are filtering somehow… don't do that.
                    let lm = response.metadata.lastModifiedMilliseconds
                    log.debug("Advancing lastModified to \(String(describing: lm)) ?? \(infoModified).")
                    self.lastModified = lm ?? infoModified
                }
            }

            log.debug("Got success response with \(response.metadata.records ?? 0) records.")

            // Store the incoming records for collection.
            self.store(response.value)

            return deferMaybe(nextOffset == nil ? .complete : .incomplete)
        }

        return fetch.bind { result in
            guard let response = result.successValue else {
                return handleFailure(result.failureValue!)
            }
            return handleSuccess(response)
        }
    }
}

enum BatchingState: Int32 {
    case mostRecentSet = 1
    case oldestSet = 2
    case backfillFromOldest = 3

    var sort: SortOption {
        switch self {
        case .mostRecentSet: return .NewestFirst
        case .oldestSet: return .OldestFirst
        case .backfillFromOldest: return .OldestFirst
        }
    }

    var direction: String {
        switch self {
        case .mostRecentSet: return "older"
        case .oldestSet: return "older"
        case .backfillFromOldest: return "newer"
        }
    }

    var asTuple: (SortOption, String) {
        return (self.sort, self.direction)
    }
}

// A mini state machine to keep track of the sorting/direction of how we batch
class BatchingStateMachine {
    let prefs: Prefs

    private(set) var current: BatchingState {
        get {
            let rawValue = self.prefs.intForKey("batchingState") ?? BatchingState.mostRecentSet.rawValue
            return BatchingState(rawValue: rawValue) ?? .mostRecentSet
        }
        set(value) {
            self.prefs.setInt(value.rawValue, forKey: "batchingState")
        }
    }

    var fetchingParameters: (SortOption, String) {
        return current.asTuple
    }
    
    init(prefs: Prefs) {
        self.prefs = prefs
    }

    func advance() {
        // Short circuit if we are already backfilling.
        guard current != .backfillFromOldest else {
            return
        }

        // Currently we change at every advance but this could be extended for more sophisticated batching strategies.
        if current == .mostRecentSet {
            current = .oldestSet
        } else if current == .oldestSet {
            current = .backfillFromOldest
        }
    }

    func reset() {
        current = .mostRecentSet
    }

    static func resetFromPrefs(_ prefs: Prefs) {
        prefs.removeObjectForKey("batchingState")
    }
}

public enum DownloadEndState: String {
    case complete                         // We're done. Records are waiting for you.
    case incomplete                       // applyBatch was called, and we think there are more records.
    case noNewData                        // There were no records.
    case interrupted                      // We got a 412 conflict when fetching the next batch.
}

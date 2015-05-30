/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()

/**
 * This exists to pass in external context: e.g., the UIApplication can
 * expose notification functionality in this way.
 */
public protocol SyncDelegate {
    func displaySentTabForURL(URL: NSURL, title: String)
    // TODO: storage.
}

// TODO: return values?
/**
 * A Synchronizer is (unavoidably) entirely in charge of what it does within a sync.
 * For example, it might make incremental progress in building a local cache of remote records, never actually performing an upload or modifying local storage.
 * It might only upload data. Etc.
 *
 * Eventually I envision an intent-like approach, or additional methods, to specify preferences and constraints
 * (e.g., "do what you can in a few seconds", or "do a full sync, no matter how long it takes"), but that'll come in time.
 *
 * A Synchronizer is a two-stage beast. It needs to support synchronization, of course; that
 * needs a completely configured client, which can only be obtained from Ready. But it also
 * needs to be able to do certain things beforehand:
 *
 * * Wipe its collections from the server (presumably via a delegate from the state machine).
 * * Prepare to sync from scratch ("reset") in response to a changed set of keys, syncID, or node assignment.
 * * Wipe local storage ("wipeClient").
 *
 * Those imply that some kind of 'Synchronizer' exists throughout the state machine. We *could*
 * pickle instructions for eventual delivery next time one is made and synchronized…
 */
public protocol Synchronizer {
    init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs)

    /**
     * Return a reason if the current state of this synchronizer -- particularly prefs and scratchpad --
     * prevent a routine sync from occurring.
     */
    func reasonToNotSync() -> SyncNotStartedReason?
}

/**
 * We sometimes wish to return something more nuanced than simple success or failure.
 * For example, refusing to sync because the engine was disabled isn't success (nothing was transferred!)
 * but it also isn't an error.
 *
 * To do this we model real failures -- something went wrong -- as failures in the Result, and
 * everything else in this status enum. This will grow as we return more details from a sync to allow
 * for batch scheduling, success-case backoff and so on.
 */
public enum SyncStatus {
    case Completed                 // TODO: we pick up a bunch of info along the way. Pass it along.
    case NotStarted(SyncNotStartedReason)
}



public typealias SyncResult = Deferred<Result<SyncStatus>>

public enum SyncNotStartedReason {
    case NoAccount
    case Offline
    case Backoff(remainingSeconds: Int)
    case EngineRemotelyNotEnabled(collection: String)
    case EngineFormatOutdated(needs: Int)
    case EngineFormatTooNew(expected: Int)   // This'll disappear eventually; we'll wipe the server and upload m/g.
    case StorageFormatOutdated(needs: Int)
    case StorageFormatTooNew(expected: Int)  // This'll disappear eventually; we'll wipe the server and upload m/g.
    case StateMachineNotReady                // Because we're not done implementing.
}

public class FatalError: SyncError {
    let message: String
    init(message: String) {
        self.message = message
    }

    public var description: String {
        return self.message
    }
}

public protocol SingleCollectionSynchronizer {
    func remoteHasChanges(info: InfoCollections) -> Bool
}

public class BaseSingleCollectionSynchronizer: SingleCollectionSynchronizer {
    let collection: String

    let scratchpad: Scratchpad
    let delegate: SyncDelegate
    let prefs: Prefs

    init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs, collection: String) {
        self.scratchpad = scratchpad
        self.delegate = delegate
        self.collection = collection
        let branchName = "synchronizer." + collection + "."
        self.prefs = basePrefs.branch(branchName)

        log.info("Synchronizer configured with prefs '\(branchName)'.")
    }

    var storageVersion: Int {
        assert(false, "Override me!")
        return 0
    }

    var lastFetched: Timestamp {
        set(value) {
            self.prefs.setLong(value, forKey: "lastFetched")
        }

        get {
            return self.prefs.unsignedLongForKey("lastFetched") ?? 0
        }
    }

    public func remoteHasChanges(info: InfoCollections) -> Bool {
        return info.modified(self.collection) > self.lastFetched
    }

    public func reasonToNotSync() -> SyncNotStartedReason? {
        if let global = self.scratchpad.global?.value {
            // There's no need to check the global storage format here; the state machine will already have
            // done so.
            if let engineMeta = self.scratchpad.global?.value.engines?[collection] {
                if engineMeta.version > self.storageVersion {
                    return .EngineFormatOutdated(needs: engineMeta.version)
                }
                if engineMeta.version < self.storageVersion {
                    return .EngineFormatTooNew(expected: engineMeta.version)
                }
            } else {
                return .EngineRemotelyNotEnabled(collection: self.collection)
            }
        } else {
            // But a missing meta/global is a real problem.
            return .StateMachineNotReady
        }

        // Success!
        return nil
    }
}
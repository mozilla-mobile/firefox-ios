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
     * Return true if the current state of this synchronizer -- particularly prefs and scratchpad --
     * allow a sync to occur.
     */
    func canSync() -> Bool
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

// These won't interrupt a multi-engine sync.
public class ContinuableError: SyncError {
    let message: String
    init(message: String) {
        self.message = message
    }

    public var description: String {
        return self.message
    }
}

public class EngineNotEnabledError: ContinuableError {
    init(engine: String) {
        super.init(message: "Engine \(engine) not enabled in meta/global.")
        log.debug("\(engine) sync disabled remotely.")
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

    public func canSync() -> Bool {
        if let engineMeta = self.scratchpad.global?.value.engines?[collection] {
            return engineMeta.version == self.storageVersion
        }
        return false
    }
}
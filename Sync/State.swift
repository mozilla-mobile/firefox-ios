/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()

/*
 * This file includes types that manage intra-sync and inter-sync metadata
 * for the use of synchronizers and the state machine.
 *
 * See docs/sync.md for details on what exactly we need to persist.
 */

public struct Fetched<T: Equatable>: Equatable {
    let value: T
    let timestamp: Timestamp
}

public func ==<T: Equatable>(lhs: Fetched<T>, rhs: Fetched<T>) -> Bool {
    return lhs.timestamp == rhs.timestamp &&
           lhs.value == rhs.value
}

/*
 * Persistence pref names.
 * Note that syncKeyBundle isn't persisted by us.
 *
 * Note also that fetched keys aren't kept in prefs: we keep the timestamp ("PrefKeysTS"),
 * and we keep a 'label'. This label is used to find the real fetched keys in the Keychain.
 */

private let PrefVersion = "_v"
private let PrefGlobal = "global"
private let PrefGlobalTS = "globalTS"
private let PrefKeyLabel = "keyLabel"
private let PrefKeysTS = "keysTS"
private let PrefLastFetched = "lastFetched"
private let PrefClientName = "clientName"
private let PrefClientGUID = "clientGUID"



/**
 * The scratchpad consists of the following:
 *
 * 1. Cached records. We cache meta/global and crypto/keys until they change.
 * 2. Metadata like timestamps, both for cached records and for server fetches.
 * 3. User preferences -- engine enablement.
 * 4. Client record state.
 *
 * Note that the scratchpad itself is immutable, but is a class passed by reference.
 * Its mutable fields can be mutated, but you can't accidentally e.g., switch out
 * meta/global and get confused.
 *
 * TODO: the Scratchpad needs to be loaded from persistent storage, and written
 * back at certain points in the state machine (after a replayable action is taken).
 */
public class Scratchpad {
    public class Builder {
        var syncKeyBundle: KeyBundle         // For the love of god, if you change this, invalidate keys, too!
        private var global: Fetched<MetaGlobal>?
        private var keys: Fetched<Keys>?
        private var keyLabel: String
        var collectionLastFetched: [String: Timestamp]
        var engineConfiguration: EngineConfiguration?
        var clientGUID: String
        var clientName: String
        var prefs: Prefs

        init(p: Scratchpad) {
            self.syncKeyBundle = p.syncKeyBundle
            self.prefs = p.prefs

            self.global = p.global

            self.keys = p.keys
            self.keyLabel = p.keyLabel

            self.collectionLastFetched = p.collectionLastFetched
            self.engineConfiguration = p.engineConfiguration
            self.clientGUID = p.clientGUID
            self.clientName = p.clientName
        }

        public func setKeys(keys: Fetched<Keys>?) -> Builder {
            self.keys = keys
            if let keys = keys {
                self.collectionLastFetched["crypto"] = keys.timestamp
            }
            return self
        }

        public func setGlobal(global: Fetched<MetaGlobal>?) -> Builder {
            self.global = global
            if let global = global {
                self.collectionLastFetched["meta"] = global.timestamp
            }
            return self
        }

        public func clearFetchTimestamps() -> Builder {
            self.collectionLastFetched = [:]
            return self
        }

        public func build() -> Scratchpad {
            return Scratchpad(
                    b: self.syncKeyBundle,
                    m: self.global,
                    k: self.keys,
                    keyLabel: self.keyLabel,
                    fetches: self.collectionLastFetched,
                    engines: self.engineConfiguration,
                    clientGUID: self.clientGUID,
                    clientName: self.clientName,
                    persistingTo: self.prefs
            )
        }
    }

    public func evolve() -> Scratchpad.Builder {
        return Scratchpad.Builder(p: self)
    }

    // This is never persisted.
    let syncKeyBundle: KeyBundle

    // Cached records.
    // This cached meta/global is what we use to add or remove enabled engines. See also
    // engineConfiguration, below.
    // We also use it to detect when meta/global hasn't changed -- compare timestamps.
    //
    // Note that a Scratchpad held by a Ready state will have the current server meta/global
    // here. That means we don't need to track syncIDs separately (which is how desktop and
    // Android are implemented).
    // If we don't have a meta/global, and thus we don't know syncIDs, it means we haven't
    // synced with this server before, and we'll do a fresh sync.
    let global: Fetched<MetaGlobal>?

    // We don't store these keys (so-called "collection keys" or "bulk keys") in Prefs.
    // Instead, we store a label, which is seeded when you first create a Scratchpad.
    // This label is used to retrieve the real keys from your Keychain.
    //
    // Note that we also don't store the syncKeyBundle here. That's always created from kB,
    // provided by the Firefox Account.
    //
    // Why don't we derive the label from your Sync Key? Firstly, we'd like to be able to
    // clean up without having your key. Secondly, we don't want to accidentally load keys
    // from the Keychain just because the Sync Key is the same -- e.g., after a node
    // reassignment. Randomly generating a label offers all of the benefits with none of the
    // problems, with only the cost of persisting that label alongside the rest of the state.
    let keys: Fetched<Keys>?
    let keyLabel: String

    // Collection timestamps.
    var collectionLastFetched: [String: Timestamp]

    // Enablement states.
    let engineConfiguration: EngineConfiguration?

    // What's our client name?
    let clientName: String
    let clientGUID: String

    // Where do we persist when told?
    let prefs: Prefs

    init(b: KeyBundle,
         m: Fetched<MetaGlobal>?,
         k: Fetched<Keys>?,
         keyLabel: String,
         fetches: [String: Timestamp],
         engines: EngineConfiguration?,
         clientGUID: String,
         clientName: String,
         persistingTo prefs: Prefs
        ) {
        self.syncKeyBundle = b
        self.prefs = prefs

        self.keys = k
        self.keyLabel = keyLabel
        self.global = m
        self.engineConfiguration = engines
        self.collectionLastFetched = fetches
        self.clientGUID = clientGUID
        self.clientName = clientName
    }

    // This should never be used in the end; we'll unpickle instead.
    // This should be a convenience initializer, but... Swift compiler bug?
    init(b: KeyBundle, persistingTo prefs: Prefs) {
        self.syncKeyBundle = b
        self.prefs = prefs

        self.keys = nil
        self.keyLabel = Bytes.generateGUID()
        self.global = nil
        self.engineConfiguration = nil
        self.collectionLastFetched = [String: Timestamp]()
        self.clientGUID = Bytes.generateGUID()
        self.clientName = DeviceInfo.defaultClientName()
    }

    // For convenience.
    func withGlobal(m: Fetched<MetaGlobal>?) -> Scratchpad {
        return self.evolve().setGlobal(m).build()
    }

    func freshStartWithGlobal(global: Fetched<MetaGlobal>) -> Scratchpad {
        // TODO: I *think* a new keyLabel is unnecessary.
        return self.evolve()
                   .setGlobal(global)
                   .setKeys(nil)
                   .clearFetchTimestamps()
                   .build()
    }

    func applyEngineChoices(old: MetaGlobal?) -> (Scratchpad, MetaGlobal?) {
        log.info("Applying engine choices from inbound meta/global.")
        log.info("Old meta/global syncID: \(old?.syncID)")
        log.info("New meta/global syncID: \(self.global?.value.syncID)")
        log.info("HACK: ignoring engine choices.")

        // TODO: detect when the sets of declined or enabled engines have changed, and update
        //       our preferences and generate a new meta/global if necessary.
        return (self, nil)
    }

    private class func unpickleV1FromPrefs(prefs: Prefs, syncKeyBundle: KeyBundle) -> Scratchpad {
        let b = Scratchpad(b: syncKeyBundle, persistingTo: prefs).evolve()

        // Do this first so that the meta/global and crypto/keys unpickling can overwrite the timestamps.
        if let lastFetched: [String: AnyObject] = prefs.dictionaryForKey(PrefLastFetched) {
            b.collectionLastFetched = optFilter(mapValues(lastFetched, { ($0 as? NSNumber)?.unsignedLongLongValue }))
        }

        if let mg = prefs.stringForKey(PrefGlobal) {
            if let mgTS = prefs.unsignedLongForKey(PrefGlobalTS) {
                if let global = MetaGlobal.fromPayload(mg) {
                    b.setGlobal(Fetched(value: global, timestamp: mgTS))
                } else {
                    log.error("Malformed meta/global in prefs. Ignoring.")
                }
            } else {
                // This should never happen.
                log.error("Found global in prefs, but not globalTS!")
            }
        }

        if let keyLabel = prefs.stringForKey(PrefKeyLabel) {
            b.keyLabel = keyLabel
            if let ckTS = prefs.unsignedLongForKey(PrefKeysTS) {
                if let keys = KeychainWrapper.stringForKey("keys." + keyLabel) {
                    // We serialize as JSON.
                    let keys = Keys(payload: KeysPayload(keys))
                    if keys.valid {
                        log.debug("Read keys from Keychain with label \(keyLabel).")
                        b.setKeys(Fetched(value: keys, timestamp: ckTS))
                    } else {
                        log.error("Invalid keys extracted from Keychain. Discarding.")
                    }
                } else {
                    log.error("Found keysTS in prefs, but didn't find keys in Keychain!")
                }
            }
        }

        b.clientName = prefs.stringForKey(PrefClientName) ?? DeviceInfo.defaultClientName()
        b.clientGUID = prefs.stringForKey(PrefClientGUID) ?? Bytes.generateGUID()

        // TODO: engineConfiguration
        return b.build()
    }


    public class func restoreFromPrefs(prefs: Prefs, syncKeyBundle: KeyBundle) -> Scratchpad? {
        if let ver = prefs.intForKey(PrefVersion) {
            switch (ver) {
            case 1:
                return unpickleV1FromPrefs(prefs, syncKeyBundle: syncKeyBundle)
            default:
                return nil
            }
        }

        log.debug("No scratchpad found in prefs.")
        return nil
    }

    /**
     * Persist our current state to our origin prefs.
     * Note that calling this from multiple threads with either mutated or evolved
     * scratchpads will cause sadness — individual writes are thread-safe, but the
     * overall pseudo-transaction is not atomic.
     */
    public func checkpoint() -> Scratchpad {
        return pickle(self.prefs)
    }

    func pickle(prefs: Prefs) -> Scratchpad {
        prefs.setInt(1, forKey: PrefVersion)
        if let global = global {
            prefs.setLong(global.timestamp, forKey: PrefGlobalTS)
            prefs.setString(global.value.toPayload().toString(), forKey: PrefGlobal)
        } else {
            prefs.removeObjectForKey(PrefGlobal)
            prefs.removeObjectForKey(PrefGlobalTS)
        }

        // We store the meat of your keys in the Keychain, using a random identifier that we persist in prefs.
        prefs.setString(self.keyLabel, forKey: PrefKeyLabel)
        if let keys = self.keys {
            let payload = keys.value.asPayload().toString(pretty: false)
            let label = "keys." + self.keyLabel
            log.debug("Storing keys in Keychain with label \(label).")
            prefs.setString(self.keyLabel, forKey: PrefKeyLabel)
            prefs.setLong(keys.timestamp, forKey: PrefKeysTS)

            // TODO: I could have sworn that we could specify kSecAttrAccessibleAfterFirstUnlock here.
            KeychainWrapper.setString(payload, forKey: label)
        } else {
            log.debug("Removing keys from Keychain.")
            KeychainWrapper.removeObjectForKey(self.keyLabel)
        }

        // TODO: engineConfiguration

        prefs.setString(clientName, forKey: PrefClientName)
        prefs.setString(clientGUID, forKey: PrefClientGUID)

        // Thanks, Swift.
        let dict = mapValues(collectionLastFetched, { NSNumber(unsignedLongLong: $0) }) as NSDictionary
        prefs.setObject(dict, forKey: PrefLastFetched)

        return self
    }
}

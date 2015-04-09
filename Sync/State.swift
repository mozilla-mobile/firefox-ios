
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

/**
 * This file includes types that manage intra-sync and inter-sync metadata
 * for the use of synchronizers and the state machine.
 *
 * See docs/sync.md for details on what exactly we need to persist.
 */

public struct Fetched<T> {
    let value: T
    let timestamp: UInt64
}

/**
 * The scratchpad consists of the following:
 *
 * 1. Cached records. We cache meta/global and crypto/keys until they change.
 * 2. Metadata like timestamps.
 *
 * Note that the scratchpad itself is immutable, but is a class passed by reference.
 * Its mutable fields can be mutated, but you can't accidentally e.g., switch out
 * meta/global and get confused.
 */
public class Scratchpad {
    let syncKeyBundle: KeyBundle

    // Cached records.
    let global: Fetched<MetaGlobal>?
    let keys: Fetched<Keys>?

    // Collection timestamps.
    let modified: [String: UInt64]

    init(b: KeyBundle) {
        self.syncKeyBundle = b
        self.modified = [String: UInt64]()
        self.keys = nil
        self.global = nil
    }

    init(b: KeyBundle, m: Fetched<MetaGlobal>?, k: Fetched<Keys>?, modified: [String: UInt64]) {
        self.syncKeyBundle = b
        self.keys = k
        self.global = m
        self.modified = modified
    }

    convenience init(b: KeyBundle, m: Fetched<MetaGlobal>?, k: Fetched<Keys>?) {
        self.init(b: b, m: m, k: k, modified: [String: UInt64]())
    }

    convenience init(b: KeyBundle, m: GlobalEnvelope?, k: Fetched<Keys>?, modified: [String: UInt64]) {
        var fetchedGlobal: Fetched<MetaGlobal>? = nil
        if let m = m {
            if let global = m.global {
                fetchedGlobal = Fetched<MetaGlobal>(value: global, timestamp: m.modified)
            }
        }
        self.init(b: b, m: fetchedGlobal, k: k, modified: modified)
    }

    func withGlobal(m: GlobalEnvelope) -> Scratchpad {
        return Scratchpad(b: self.syncKeyBundle, m: m, k: self.keys, modified: self.modified)
    }

    func withKeys(k: Keys, t: UInt64) -> Scratchpad {
        let f = Fetched(value: k, timestamp: t)
        return Scratchpad(b: self.syncKeyBundle, m: self.global, k: f, modified: self.modified)
    }
}

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

/**
 * The scratchpad consists of the following:
 *
 * 1. Cached records. For example, we typically fetch info/collections only once,
 *    caching it during a sync. We cache meta/global until it changes.
 * 2. Metadata like timestamps.
 *
 * Note that the scratchpad itself is immutable, but is a class passed by reference.
 * Its mutable fields can be mutated, but you can't accidentally e.g., switch out
 * meta/global and get confused.
 */
public class Scratchpad {
    let syncKeyBundle: KeyBundle

    // Cached records.
    let global: MetaGlobal?
    let infoCollections: InfoCollections?

    init(b: KeyBundle) {
        self.syncKeyBundle = b
    }

    init(b: KeyBundle, m: MetaGlobal?, i: InfoCollections?) {
        self.syncKeyBundle = b
        self.global = m
        self.infoCollections = i
    }

    convenience init(b: KeyBundle, m: GlobalEnvelope?, i: InfoCollections?) {
        self.init(b: b, m: m?.global, i: i)
    }

    func withGlobal(m: GlobalEnvelope) -> Scratchpad {
        return Scratchpad(b: self.syncKeyBundle, m: m, i: self.infoCollections)
    }

    func withInfo(i: InfoCollections) -> Scratchpad {
        return Scratchpad(b: self.syncKeyBundle, m: self.global, i: i)
    }
}
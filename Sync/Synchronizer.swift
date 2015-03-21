/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// TODO: return values?
/**
 * A Synchronizer is (unavoidably) entirely in charge of what it does within a sync.
 * For example, it might make incremental progress in building a local cache of remote records, never actually performing an upload or modifying local storage.
 * It might only upload data. Etc.
 *
 * Eventually I envision an intent-like approach, or additional methods, to specify preferences and constraints
 * (e.g., "do what you can in a few seconds", or "do a full sync, no matter how long it takes"), but that'll come in time.
 */
public protocol Synchronizer {
    init(info: InfoCollections, prefs: Prefs)
    func synchronize()
}

public class ClientsSynchronizer: Synchronizer {
    private let info: InfoCollections
    private let prefs: Prefs

    private let prefix = "clients"
    private let collection = "clients"

    required public init(info: InfoCollections, prefs: Prefs) {
        self.info = info
        self.prefs = prefs
    }

    public func synchronize() {
        if let last = prefs.longForKey(self.prefix + "last") {
            if last == info.modified(self.collection) {
                // Nothing to do.
                return;
            }
        }
    }
}
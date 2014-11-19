/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * Encapsulates a meta/global, identity-derived keys, and keys.
 */
public class SyncMeta {
    let syncKey: KeyBundle

    var keys: Keys?
    var global: AnyObject?

    public init(syncKey: KeyBundle) {
        self.syncKey = syncKey
    }
}
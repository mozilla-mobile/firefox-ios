/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

/**
 * This exists to allow resets after meta/global or crypto/key changes.
 *
 * 'Reset' in this case means that timestamps and progress tracking are
 * discarded: this storage is reconfigured such that all data will be
 * reuploaded, and all data will be re-merged as necessary.
 *
 * This protocol is primarily consumed by `ResettableSynchronizer`, and
 * is invoked when a significant server change is observed — changed keys,
 * changed engine elections or syncIDs, or a node reassignment.
 */
public protocol ResettableSyncStorage {
    func resetClient() -> Success
}

public protocol AccountRemovalDelegate {
    func onRemovedAccount() -> Success
}

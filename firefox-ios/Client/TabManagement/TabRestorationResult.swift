// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// The output of a tab restoration pass, consumed by `TabManagerImplementation.applyRestorationResult(_:)`.
struct TabRestorationResult {
    /// The tabs built from persisted data, in the order they were stored.
    let restoredTabs: [Tab]
    /// The UUID of the tab that was active at the time of the last save, or `nil` if it did not survive filtering.
    let selectedTabUUID: TabUUID?
    let windowUUID: WindowUUID
}

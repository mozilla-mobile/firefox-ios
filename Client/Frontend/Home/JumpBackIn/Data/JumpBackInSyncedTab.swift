// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// The filtered jumpBack in synced tab to display to the user.
struct JumpBackInSyncedTab {
    let client: RemoteClient
    let tab: RemoteTab
}

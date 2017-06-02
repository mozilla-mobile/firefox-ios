/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sync

// This is a cut down version of the Profile. 
// This will only ever be used in the NotificationService extension.
// It allows us to customize the SyncDelegate, and later the SyncManager.
class ExtensionProfile: BrowserProfile {
    let syncDelegate: SyncDelegate

    init(localName: String, delegate: SyncDelegate) {
        syncDelegate = delegate
        super.init(localName: localName, app: nil, clear: false)
    }

    override func getSyncDelegate() -> SyncDelegate {
        return syncDelegate
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sync

// This is a cut down version of the Profile. 
// This will only ever be used in the NotificationService extension.
// It allows us to customize the SyncDelegate, and later the SyncManager.
class ExtensionProfile: BrowserProfile {
    var syncDelegate: SyncDelegate!

    init(localName: String) {
        super.init(localName: localName, app: nil, clear: false)
        syncManager = ExtensionSyncManager(profile: self)
    }

    override func getSyncDelegate() -> SyncDelegate {
        return syncDelegate
    }

}

class ExtensionSyncManager: BrowserProfile.BrowserSyncManager {

    init(profile: ExtensionProfile) {
        super.init(profile: profile)
    }

    override func canSendUsageData() -> Bool {
        return false
    }
}

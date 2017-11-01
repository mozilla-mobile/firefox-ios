/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Shared
import Sync

// This is a cut down version of the Profile. 
// This will only ever be used in the NotificationService extension.
// It allows us to customize the SyncDelegate, and later the SyncManager.
class ExtensionProfile: BrowserProfile {
    init(localName: String) {
        super.init(localName: localName, clear: false)
        self.syncManager = ExtensionSyncManager(profile: self)
    }
}

fileprivate let extensionSafeNames = Set(["clients"])

// Mock class required by `BrowserProfile`
open class PanelDataObservers {
    init(profile: Any) {}
}

// Mock class required by `BrowserProfile`
open class SearchEngines {
    init(prefs: Any, files: Any) {}
}

class ExtensionSyncManager: BrowserProfile.BrowserSyncManager {
    init(profile: ExtensionProfile) {
        super.init(profile: profile)
    }

    // We don't want to send ping data at all while we're in the extension.
    override func canSendUsageData() -> Bool {
        return false
    }

    // We should probably only want to sync client commands while we're in the extension.
    override func syncNamedCollections(why: SyncReason, names: [String]) -> Success {
        let names = names.filter { extensionSafeNames.contains($0) }
        return super.syncNamedCollections(why: why, names: names)
    }

    override func takeActionsOnEngineStateChanges<T: EngineStateChanges>(_ changes: T) -> Deferred<Maybe<T>> {
        return deferMaybe(changes)
    }
}

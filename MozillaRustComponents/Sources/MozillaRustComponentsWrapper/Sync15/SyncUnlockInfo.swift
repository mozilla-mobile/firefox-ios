/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

/// Set of arguments required to sync.
open class SyncUnlockInfo {
    public var kid: String
    public var fxaAccessToken: String
    public var syncKey: String
    public var tokenserverURL: String
    public var loginEncryptionKey: String
    public var tabsLocalId: String?

    public init(
        kid: String,
        fxaAccessToken: String,
        syncKey: String,
        tokenserverURL: String,
        loginEncryptionKey: String,
        tabsLocalId: String? = nil
    ) {
        self.kid = kid
        self.fxaAccessToken = fxaAccessToken
        self.syncKey = syncKey
        self.tokenserverURL = tokenserverURL
        self.loginEncryptionKey = loginEncryptionKey
        self.tabsLocalId = tabsLocalId
    }
}

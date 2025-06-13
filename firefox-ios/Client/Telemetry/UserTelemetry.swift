// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct UserTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// Records the UID of a user signed into their Firefox Account on a special `fx-accounts` ping. Once the UID is
    /// recorded, the ping is immediately submitted.
    /// - Parameter uid: The user's Firefox Account UID.
    func setFirefoxAccountID(uid: String) {
        gleanWrapper.recordString(for: GleanMetrics.UserClientAssociation.uid, value: uid)

        // We send the `fx-accounts` ping now that the payload data has been set
        GleanMetrics.Pings.shared.fxAccounts.submit()
    }
}

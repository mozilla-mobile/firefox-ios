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

    /// Recorded when a user taps a row on the settings screen (or one of its subscreens) to drill deeper into the settings.
    /// - Parameter option: A unique identifier for the selected row. Identifies the row tapped, not the screen shown.
    func setFirefoxAccountID(uid: String) {
        gleanWrapper.recordString(for: GleanMetrics.UserClientAssociation.uid, value: uid)

        // We send the `fx-accounts` ping now that the payload data has been set
        GleanMetrics.Pings.shared.fxAccounts.submit()
    }
}

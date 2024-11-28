// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol GleanWrapper {
    func handleDeeplinkUrl(url: URL)
    func submitPing()
    func setUpload(isEnabled: Bool)
}

/// Glean wrapper to abstract Glean from our application
struct DefaultGleanWrapper: GleanWrapper {
    public static let shared = DefaultGleanWrapper()

    func handleDeeplinkUrl(url: URL) {
        Glean.shared.handleCustomUrl(url: url)
    }
    func setUpload(isEnabled: Bool) {
        Glean.shared.setCollectionEnabled(isEnabled)
    }
    func submitPing() {
        GleanMetrics.Pings.shared.firstSession.submit()
    }
}

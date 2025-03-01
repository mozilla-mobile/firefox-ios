// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

// Contextual identifier used for the sponsored tiles in top sites and the suggestions in the search view
struct TelemetryContextualIdentifier {
    enum UserDefaultsKey: String {
        case keyContextId = "com.moz.contextId.key"
    }

    static var contextId: String? {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyContextId.rawValue) as? String }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyContextId.rawValue) }
    }

    static func clearUserDefaults() {
        TelemetryContextualIdentifier.contextId = nil
    }

    /// Setup the contextual identifier used for some telemetry events
    /// - Parameter allowed: True when we should setup the GleanMetrics TopSites at the same time as ensuring
    /// the `UserDefaults` have a proper `contextId` available for this user. False when the ToS are not accepted.
    static func setupContextId(isGleanMetricsAllowed allowed: Bool = true) {
        // Use existing client UUID, if doesn't exists create a new one
        if let stringContextId = contextId, let clientUUID = UUID(uuidString: stringContextId), allowed {
            GleanMetrics.TopSites.contextId.set(clientUUID)
        } else {
            let newUUID = UUID()
            contextId = newUUID.uuidString

            guard allowed else { return }
            GleanMetrics.TopSites.contextId.set(newUUID)
        }
    }
}

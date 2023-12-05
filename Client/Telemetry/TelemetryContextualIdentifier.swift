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

    static func setupContextId() {
        // Use existing client UUID, if doesn't exists create a new one
        if let stringContextId = contextId, let clientUUID = UUID(uuidString: stringContextId) {
            GleanMetrics.TopSites.contextId.set(clientUUID)
        } else {
            let newUUID = UUID()
            GleanMetrics.TopSites.contextId.set(newUUID)
            contextId = newUUID.uuidString
        }
    }
}

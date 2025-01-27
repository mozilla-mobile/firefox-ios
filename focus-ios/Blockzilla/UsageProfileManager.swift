// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Foundation

final class UsageProfileManager {
    struct Constants {
        static let profileId = "profileId"
        static let canaryUUID = UUID(uuidString: "beefbeef-beef-beef-beef-beeefbeefbee")!
    }
    
    static func unsetUsageProfileId() {
        UserDefaults.standard.removeObject(forKey: Constants.profileId)
        GleanMetrics.Usage.profileId.set(Constants.canaryUUID)
    }
    
    static func checkAndSetUsageProfileId() {
        if let uuidString = UserDefaults.standard.string(forKey: Constants.profileId),
           let uuid = UUID(uuidString: uuidString) {
            GleanMetrics.Usage.profileId.set(uuid)
        } else {
            let uuid = GleanMetrics.Usage.profileId.generateAndSet()
            UserDefaults.standard.set(uuid.uuidString, forKey: Constants.profileId)
        }
    }
}

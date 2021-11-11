// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class ChronTabsUserResearch {
    
    // MARK: - Properties
    
    // Constants
    private let enrollmentKey = "chronTabsUserResearchEnrollmentKey"
    private let chronTabsUserResearchKey = "chronTabsUserResearchKey"
    private let abTestName = "Chronological Tabs AB Test Prod"
    
    // Saving user defaults
    private let defaults = UserDefaults.standard
    
    // New tab button state
    // True: Show new tab button
    // False: Hide new tab button
    var chronTabsState: Bool? {
        set(value) {
            if value == nil {
                defaults.removeObject(forKey: chronTabsUserResearchKey)
            } else {
                defaults.set(value, forKey: chronTabsUserResearchKey)
            }
        }
        get {
            guard let value = defaults.value(forKey: chronTabsUserResearchKey) as? Bool else {
                return nil
            }
            return value
        }
    }
    
    var hasEnrolled: Bool {
        set(value) {
            defaults.set(value, forKey: enrollmentKey)
        }
        get {
            defaults.bool(forKey: enrollmentKey)
        }
    }
}

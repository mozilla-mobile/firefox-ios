/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class NewTabUserResearch {
    
    // MARK: - Properties
    
    // Constants
    private let enrollmentKey = "newTabUserResearchEnrollmentKey"
    private let newTabUserResearchKey = "newTabUserResearchKey"
    private let abTestName = "New Tab AB Test Prod (Fix)"
    
    // Saving user defaults
    private let defaults = UserDefaults.standard
    
    // Note: Until AB Test is finalized we are going to disable it and have new tab state as False
    var newTabState = false
//    // New tab button state
//    // True: Show new tab button
//    // False: Hide new tab button
//    var newTabState: Bool? {
//        set(value) {
//            if value == nil {
//                defaults.removeObject(forKey: newTabUserResearchKey)
//            } else {
//                defaults.set(value, forKey: newTabUserResearchKey)
//            }
//        }
//        get {
//            guard let value = defaults.value(forKey: newTabUserResearchKey) as? Bool else {
//                return nil
//            }
//            return value
//        }
//    }
    
    var hasEnrolled: Bool {
        set(value) {
            defaults.set(value, forKey: enrollmentKey)
        }
        get {
            defaults.bool(forKey: enrollmentKey)
        }
    }
}

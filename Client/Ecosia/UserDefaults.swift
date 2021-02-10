/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension UserDefaults {
    private static let synch = UserDefaults(suiteName: "group.com.ecosia.ecosiaapp.firefox")! //TODO: change for LIVE version
    private static let _statistics = "statistics"
    
    static var statistics: Data? {
        get {
            synch.data(forKey: _statistics)
        }
        set {
            newValue.map {
                synch.setValue($0, forKey: _statistics)
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Data Model
struct DefaultBrowserCardModel {
    //TODO: fill this
}

class DefaultBrowserCardViewModel {
    //  Internal vars
    var model: DefaultBrowserCardModel?
    var goToSettings: (() -> Void)?
    
    init() {
        setupUpdateModel()
    }

    private func setupUpdateModel() {
        //TODO: fill ths
    }
    
    static func shouldShowDefaultBrowserCard(userPrefs: Prefs) -> Bool {
        // 0,1,2 so we show on 3rd session as a requirement
        let maxSessionCount = 2
        var shouldShow = false
        // Session count
        var sessionCount: Int32 = 0
        
        // Get the session count from preferences
        if let currentSessionCount = userPrefs.intForKey(PrefsKeys.KeyDefaultBrowserCardSessionCount) {
            sessionCount = currentSessionCount
        }

        // increase session count value
        if sessionCount < maxSessionCount && sessionCount != -1 {
            userPrefs.setInt(sessionCount + 1, forKey: PrefsKeys.KeyInstallSession)
        // reached max count, show card
        } else if sessionCount == maxSessionCount {
            userPrefs.setInt(-1, forKey: PrefsKeys.KeyInstallSession)
            shouldShow = true
        }

        return shouldShow
    }
}

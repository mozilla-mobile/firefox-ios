/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Intents
import IntentsUI

class SiriShortcuts {
    enum activityType: String {
        case erase
        case eraseAndOpen = "org.mozilla.ios.Klar.eraseAndOpen"
        case openURL
    }
    
    func getActivity(for type: activityType) -> NSUserActivity? {
        switch type {
        case .eraseAndOpen:
            return eraseAndOpenActivity
        default:
            break
        }
        return nil
    }
    
    private var eraseAndOpenActivity: NSUserActivity? = {
        if #available(iOS 12.0, *) {
            let activity = NSUserActivity(activityType: activityType.eraseAndOpen.rawValue)
            activity.title = UIConstants.strings.eraseAndOpenSiri
            activity.userInfo = [:]
            activity.isEligibleForSearch = true
            activity.isEligibleForPrediction = true
            activity.suggestedInvocationPhrase = UIConstants.strings.eraseAndOpenSiri
            activity.persistentIdentifier = NSUserActivityPersistentIdentifier(activityType.eraseAndOpen.rawValue)
            return activity
        } else {
            return nil
        }
    }()
}

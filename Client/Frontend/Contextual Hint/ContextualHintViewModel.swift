/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

enum ContextualHintViewType {
    case jumpBackIn
}

class ContextualHintViewModel {

    func shouldPresentContextualHint(profile: Profile, type: ContextualHintViewType) -> Bool {
        switch type {
        case .jumpBackIn:
            guard let contextualHintData = profile.prefs.boolForKey(PrefsKeys.ContextualHintJumpBackinKey) else {
                return true
            }
            return contextualHintData
        }
    }
    
    func markContextualHintPresented(profile: Profile, type: ContextualHintViewType) {
        switch type {
        case .jumpBackIn:
            profile.prefs.setBool(false, forKey: PrefsKeys.ContextualHintJumpBackinKey)
        }
    }
}

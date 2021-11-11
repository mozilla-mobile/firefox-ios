// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

enum ContextualHintViewType {
    case jumpBackIn
    
    func descriptionForHint() -> String {
        switch self {
        case .jumpBackIn:
            return String.ContextualHints.PersonalizedHome
        }
    }
}

class ContextualHintViewModel {

    var hintType: ContextualHintViewType?
    
    convenience init(hintType: ContextualHintViewType?) {
        self.init()
        self.hintType = hintType
    }
    
    func shouldPresentContextualHint(profile: Profile) -> Bool {
        guard let type = hintType else { return false }
        switch type {
        case .jumpBackIn:
            guard let contextualHintData = profile.prefs.boolForKey(PrefsKeys.ContextualHintJumpBackinKey) else {
                return true
            }
            return contextualHintData
        }
    }
    
    func markContextualHintPresented(profile: Profile) {
        guard let type = hintType else { return }
        switch type {
        case .jumpBackIn:
            profile.prefs.setBool(false, forKey: PrefsKeys.ContextualHintJumpBackinKey)
        }
    }
}

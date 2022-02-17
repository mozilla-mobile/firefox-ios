// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import UIKit

enum ContextualHintViewType {
    typealias ContextualHints = String.ContextualHints.FirefoxHomepage
    
    case jumpBackIn
//    case inactiveTabs
    
    func descriptionForHint() -> String {
        switch self {
        case .jumpBackIn:
            return ContextualHints.JumpBackIn.PersonalizedHome
//        case .inactiveTabs:
//            return ContextualHints.TabsTray.InactiveTabs.Body
        }
    }
}

class ContextualHintViewModel {

    var hintType: ContextualHintViewType
    var profile: Profile
    
    init(forHintType hintType: ContextualHintViewType, with profile: Profile) {
        self.hintType = hintType
        self.profile = profile
    }
    
    func shouldPresentContextualHint() -> Bool {
        guard isDeviceHintReady else { return false }
        switch hintType {
        case .jumpBackIn:
            guard let contextualHintData = profile.prefs.boolForKey(PrefsKeys.ContextualHints.JumpBackinKey) else {
                return true
            }
            return contextualHintData
        }
    }
    
    func markContextualHintPresented() {
        switch hintType {
        case .jumpBackIn:
            profile.prefs.setBool(false, forKey: PrefsKeys.ContextualHints.JumpBackinKey)
        }
    }

    // Do not present contextual hint in landscape on iPhone
    private var isDeviceHintReady: Bool {
        !UIWindow.isLandscape || UIDevice.current.userInterfaceIdiom == .pad
    }
}

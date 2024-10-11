// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol ContextualHintPrefsKeysProvider {
    func prefsKey(for hintType: ContextualHintType) -> String
}

extension ContextualHintPrefsKeysProvider {
    typealias CFRPrefsKeys = PrefsKeys.ContextualHints

    func prefsKey(for hintType: ContextualHintType) -> String {
        switch hintType {
        case .dataClearance: return CFRPrefsKeys.dataClearanceKey.rawValue
        case .inactiveTabs: return CFRPrefsKeys.inactiveTabsKey.rawValue
        case .jumpBackIn: return CFRPrefsKeys.jumpBackinKey.rawValue
        case .jumpBackInSyncedTab: return CFRPrefsKeys.jumpBackInSyncedTabKey.rawValue
        case .toolbarLocation: return CFRPrefsKeys.toolbarOnboardingKey.rawValue
        case .shoppingExperience: return CFRPrefsKeys.shoppingOnboardingKey.rawValue
        case .navigation: return CFRPrefsKeys.navigationKey.rawValue
        }
    }
}

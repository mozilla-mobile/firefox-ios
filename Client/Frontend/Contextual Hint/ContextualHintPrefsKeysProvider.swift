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
        case .inactiveTabs: return CFRPrefsKeys.InactiveTabsKey.rawValue
        case .jumpBackIn: return CFRPrefsKeys.JumpBackinKey.rawValue
        case .jumpBackInSyncedTab: return CFRPrefsKeys.JumpBackInSyncedTabKey.rawValue
        case .toolbarLocation: return CFRPrefsKeys.ToolbarOnboardingKey.rawValue
        }
    }

}

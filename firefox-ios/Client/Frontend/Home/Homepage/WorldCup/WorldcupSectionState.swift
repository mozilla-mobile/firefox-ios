// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit

/// State for the World Cup promo card displayed on the homepage.
struct WorldcupSectionState: StateType, Equatable, Hashable, FeatureFlaggable {
    var windowUUID: WindowUUID
    var shouldShowSection: Bool

    init(profile: Profile = AppContainer.shared.resolve(), windowUUID: WindowUUID) {
        let shouldShowSection = profile.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupSection) ?? true
        self.init(windowUUID: windowUUID, shouldShowSection: shouldShowSection)
    }

    private init(windowUUID: WindowUUID, shouldShowSection: Bool) {
        self.windowUUID = windowUUID
        self.shouldShowSection = shouldShowSection
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action.actionType {
        case WorldCupActionType.closedCard:
            return WorldcupSectionState(windowUUID: state.windowUUID, shouldShowSection: false)
        case WorldCupActionType.didChangeHomepageSettings:
            guard let show = (action as? WorldCupAction)?.shouldShowHomepageWorldCupSection else {
                return state
            }
            return WorldcupSectionState(windowUUID: state.windowUUID, shouldShowSection: show)
        default:
            return state
        }
    }

    static func defaultState(from state: WorldcupSectionState) -> WorldcupSectionState {
        return state
    }
}

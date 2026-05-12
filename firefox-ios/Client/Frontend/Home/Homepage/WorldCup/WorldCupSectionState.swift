// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit

/// State for the World Cup promo card displayed on the homepage.
struct WorldCupSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var shouldShowSection: Bool
    var isMilestone2: Bool
    
    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.shouldShowSection = false
        self.isMilestone2 = false
    }

    private init(
        windowUUID: WindowUUID,
        shouldShowSection: Bool,
        isMilestone2: Bool,
    ) {
        self.windowUUID = windowUUID
        self.shouldShowSection = shouldShowSection
        self.isMilestone2 = isMilestone2
    }

    static let reducer: Reducer<Self> = { state, action in
        guard let action = action as? WorldCupAction else {
            return state
        }
        switch action.actionType {
        case WorldCupMiddlewareActionType.didUpdate:
            return WorldCupSectionState(
                windowUUID: action.windowUUID,
                shouldShowSection: action.shouldShowHomepageWorldCupSection,
                isMilestone2: action.shouldShowMilestone2,
            )
        default:
            return state
        }
    }

    static func defaultState(from state: WorldCupSectionState) -> WorldCupSectionState {
        return state
    }
}

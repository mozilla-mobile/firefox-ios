// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux
import Shared

/// State for the World Cup section that is used in the homepage view
@CopyWithUpdates
struct WorldCupSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    let shouldShowSection: Bool

    init(windowUUID: WindowUUID) {
        let userPreferences: UserFeaturePreferring = AppContainer.shared.resolve()
        let shouldShowSection = userPreferences.isHomepageWorldCupSectionEnabled
        self.init(
            windowUUID: windowUUID,
            shouldShowSection: shouldShowSection
        )
    }

    private init(
        windowUUID: WindowUUID,
        shouldShowSection: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldShowSection = shouldShowSection
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case WorldCupActionType.didChangeHomepageSettings:
            return handleSettingsToggleAction(action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleSettingsToggleAction(
        _ action: Action,
        state: WorldCupSectionState
    ) -> WorldCupSectionState {
        guard let worldCupAction = action as? WorldCupAction else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            shouldShowSection: worldCupAction.shouldShowHomepageWorldCupSection
        )
    }

    static func defaultState(from state: WorldCupSectionState) -> WorldCupSectionState {
        return state.copyWithUpdates()
    }
}

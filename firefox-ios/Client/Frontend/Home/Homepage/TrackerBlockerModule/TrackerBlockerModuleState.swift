// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux
import Shared

@CopyWithUpdates
struct TrackerBlockerModuleState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    let shouldShowSection: Bool

    init(
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        windowUUID: WindowUUID
    ) {
        self.init(
            windowUUID: windowUUID,
            shouldShowSection: featureFlagsProvider.isEnabled(.homepageTrackerBlockerModule)
                && userPreferences.getPreferenceFor(.homepageTrackerBlockerModule)
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
        case TrackerBlockerModuleActionType.toggleShowSectionSetting:
            return handleSettingsToggleAction(action, state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleSettingsToggleAction(
        _ action: Action,
        state: TrackerBlockerModuleState,
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve()
    ) -> TrackerBlockerModuleState {
        guard featureFlagsProvider.isEnabled(.homepageTrackerBlockerModule) else {
            return state.copyWithUpdates(shouldShowSection: false)
        }

        guard let trackerBlockerModuleAction = action as? TrackerBlockerModuleAction,
              let isEnabled = trackerBlockerModuleAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            shouldShowSection: isEnabled
        )
    }

    static func defaultState(from state: TrackerBlockerModuleState) -> TrackerBlockerModuleState {
        return state.copyWithUpdates()
    }
}

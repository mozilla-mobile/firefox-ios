// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux
import Shared

@Copyable
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

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
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
            return state.copy(shouldShowSection: false)
        }

        guard let trackerBlockerModuleAction = action as? TrackerBlockerModuleAction,
              let isEnabled = trackerBlockerModuleAction.isEnabled
        else {
            return defaultState(from: state)
        }

        return state.copy(shouldShowSection: isEnabled)
    }

    static func defaultState(from state: TrackerBlockerModuleState) -> TrackerBlockerModuleState {
        return state
    }
}

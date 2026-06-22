// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

/// Public surface for reading the Quick Answers feature's enabled state.
/// Used to derive the initial value for the header state.
protocol QuickAnswersStore {
    /// Whether the Quick Answers feature flag is enabled and the user preference for it is enabled.
    var isQuickAnswersEnabled: Bool { get }
}

@MainActor
final class QuickAnswersMiddleware: QuickAnswersStore {
    private let prefs: Prefs
    let featureFlagsProvider: FeatureFlagProviding
    let userPreferences: UserFeaturePreferring

    nonisolated var isQuickAnswersEnabled: Bool {
        let isFeatureFlagEnabled = featureFlagsProvider.isEnabled(.quickAnswers)
        let isUserPreferencesEnabled = userPreferences.getPreferenceFor(.quickAnswers)
        return isFeatureFlagEnabled && isUserPreferencesEnabled
    }

    nonisolated init(
        profile: Profile = AppContainer.shared.resolve(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve()
    ) {
        self.prefs = profile.prefs
        self.featureFlagsProvider = featureFlagsProvider
        self.userPreferences = userPreferences
    }

    lazy var quickAnswersProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize, HomepageActionType.viewWillAppear:
            self.handleInitializeAction(action: action)
        case QuickAnswersActionType.didSettingsChange:
            self.handleDidSettingsChangeAction(action: action)
        default:
            break
        }
    }

    private func handleInitializeAction(action: Action) {
        store.dispatch(QuickAnswersMiddlewareAction(
            isQuickAnswersEnabled: isQuickAnswersEnabled,
            windowUUID: action.windowUUID,
            actionType: QuickAnswersMiddlewareActionType.didInitialize
        ))
    }

    private func handleDidSettingsChangeAction(action: Action) {
        store.dispatch(QuickAnswersMiddlewareAction(
            isQuickAnswersEnabled: isQuickAnswersEnabled,
            windowUUID: action.windowUUID,
            actionType: QuickAnswersMiddlewareActionType.didUpdateSettings
        ))
    }
}

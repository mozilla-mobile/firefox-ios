// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

protocol QuickAnswersStore {
    /// Whether the Quick Answers feature flag is enabled and the user preference for it is enabled.
    var isQuickAnswersEnabled: Bool { get }
}

final class QuickAnswersMiddleware: QuickAnswersStore {
    private let prefs: Prefs
    let featureFlagsProvider: FeatureFlagProviding
    let userPreferences: UserFeaturePreferring

    var isQuickAnswersEnabled: Bool {
        let isFeatureFlagEnabled = featureFlagsProvider.isEnabled(.quickAnswers)
        let isUserPreferencesEnabled = userPreferences.getPreferenceFor(.quickAnswers)
        return isFeatureFlagEnabled && isUserPreferencesEnabled
    }

    init(
        profile: Profile = AppContainer.shared.resolve(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve()
    ) {
        self.prefs = profile.prefs
        self.featureFlagsProvider = featureFlagsProvider
        self.userPreferences = userPreferences
    }

    @MainActor
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

    @MainActor
    private func handleInitializeAction(action: Action) {
        store.dispatch(QuickAnswersMiddlewareAction(
            isQuickAnswersEnabled: isQuickAnswersEnabled,
            windowUUID: action.windowUUID,
            actionType: QuickAnswersMiddlewareActionType.didInitialize
        ))
    }

    @MainActor
    private func handleDidSettingsChangeAction(action: Action) {
        store.dispatch(QuickAnswersMiddlewareAction(
            isQuickAnswersEnabled: isQuickAnswersEnabled,
            windowUUID: action.windowUUID,
            actionType: QuickAnswersMiddlewareActionType.didUpdateSettings
        ))
    }
}

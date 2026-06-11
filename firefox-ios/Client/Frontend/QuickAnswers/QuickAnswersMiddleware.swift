// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

@MainActor
final class QuickAnswersMiddleware {
    private let prefs: Prefs
    let featureFlagsProvider: FeatureFlagProviding
    private var isQuickAnswersEnabled: Bool {
        let isFeatureFlagEnabled = featureFlagsProvider.isEnabled(.quickAnswers)
        // default value is set to true like in the settings.
        let isUserPreferencesEnabled = prefs.boolForKey(PrefsKeys.Settings.quickAnswersFeature) ?? true
        return isFeatureFlagEnabled && isUserPreferencesEnabled
    }

    init(
        profile: Profile = AppContainer.shared.resolve(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve()
    ) {
        self.prefs = profile.prefs
        self.featureFlagsProvider = featureFlagsProvider
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

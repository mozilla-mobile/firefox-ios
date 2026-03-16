// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

@MainActor
final class TranslationSettingsMiddleware {
    private let profile: Profile
    private let manager: PreferredTranslationLanguagesManager
    private let modelsFetcher: TranslationModelsFetcherProtocol

    init(profile: Profile = AppContainer.shared.resolve(),
         manager: PreferredTranslationLanguagesManager? = nil,
         modelsFetcher: TranslationModelsFetcherProtocol = ASTranslationModelsFetcher.shared) {
        self.profile = profile
        self.manager = manager ?? PreferredTranslationLanguagesManager(prefs: profile.prefs)
        self.modelsFetcher = modelsFetcher
    }

    lazy var translationSettingsProvider: Middleware<AppState> = { state, action in
        guard let action = action as? TranslationSettingsViewAction else { return }
        self.handleAction(action)
    }

    private func handleAction(_ action: TranslationSettingsViewAction) {
        switch action.actionType {
        case TranslationSettingsViewActionType.viewDidLoad:
            Task { @MainActor in await self.loadSettings(windowUUID: action.windowUUID) }

        case TranslationSettingsViewActionType.toggleTranslationsEnabled:
            let current = profile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
            let newValue = !current
            profile.prefs.setBool(newValue, forKey: PrefsKeys.Settings.translationsFeature)
            store.dispatch(ToolbarAction(
                translationConfiguration: TranslationConfiguration(prefs: profile.prefs, state: .inactive),
                windowUUID: action.windowUUID,
                actionType: ToolbarActionType.didTranslationSettingsChange
            ))
            store.dispatch(TranslationSettingsMiddlewareAction(
                isTranslationsEnabled: newValue,
                windowUUID: action.windowUUID,
                actionType: TranslationSettingsMiddlewareActionType.didUpdateSettings
            ))

        default:
            break
        }
    }

    private func loadSettings(windowUUID: WindowUUID) async {
        let supported = await modelsFetcher.fetchSupportedTargetLanguages()
        let preferred = manager.preferredLanguages(supportedTargetLanguages: supported)
        let isEnabled = profile.prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
        store.dispatch(TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: isEnabled,
            preferredLanguages: preferred,
            supportedLanguages: supported,
            windowUUID: windowUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        ))
    }
}

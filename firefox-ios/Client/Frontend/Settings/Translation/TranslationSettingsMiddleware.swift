// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

@MainActor
final class TranslationSettingsMiddleware {
    private let prefs: Prefs
    private let manager: PreferredTranslationLanguagesManager
    private let modelsFetcher: TranslationModelsFetcherProtocol

    init(profile: Profile = AppContainer.shared.resolve(),
         manager: PreferredTranslationLanguagesManager? = nil,
         modelsFetcher: TranslationModelsFetcherProtocol = ASTranslationModelsFetcher.shared) {
        self.prefs = profile.prefs
        self.manager = manager ?? PreferredTranslationLanguagesManager(prefs: profile.prefs)
        self.modelsFetcher = modelsFetcher
    }

    lazy var translationSettingsProvider: Middleware<AppState> = { [weak self] state, action in
        guard let self, let action = action as? TranslationSettingsViewAction else { return }
        self.handleAction(action)
    }

    private func handleAction(_ action: TranslationSettingsViewAction) {
        switch action.actionType {
        case TranslationSettingsViewActionType.viewDidLoad:
            Task { await self.loadSettings(windowUUID: action.windowUUID) }

        case TranslationSettingsViewActionType.toggleTranslationsEnabled:
            let current = prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
            let newValue = !current
            prefs.setBool(newValue, forKey: PrefsKeys.Settings.translationsFeature)
            store.dispatch(ToolbarAction(
                translationConfiguration: TranslationConfiguration(prefs: prefs, state: .inactive),
                windowUUID: action.windowUUID,
                actionType: ToolbarActionType.didTranslationSettingsChange
            ))
            store.dispatch(TranslationSettingsMiddlewareAction(
                isTranslationsEnabled: newValue,
                windowUUID: action.windowUUID,
                actionType: TranslationSettingsMiddlewareActionType.didUpdateSettings
            ))

        case TranslationSettingsViewActionType.addLanguage:
            guard let code = action.languageCode else { break }
            let updated = manager.addLanguage(code)
            store.dispatch(TranslationSettingsMiddlewareAction(
                preferredLanguages: updated,
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
        let isEnabled = prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
        store.dispatch(TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: isEnabled,
            preferredLanguages: preferred,
            supportedLanguages: supported,
            windowUUID: windowUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        ))
    }
}

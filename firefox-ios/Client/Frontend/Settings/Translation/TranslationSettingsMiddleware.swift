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
    private let localeProvider: LocaleProvider

    init(profile: Profile = AppContainer.shared.resolve(),
         manager: PreferredTranslationLanguagesManager? = nil,
         modelsFetcher: TranslationModelsFetcherProtocol = ASTranslationModelsFetcher.shared,
         localeProvider: LocaleProvider = SystemLocaleProvider()) {
        self.prefs = profile.prefs
        self.manager = manager ?? PreferredTranslationLanguagesManager(prefs: profile.prefs)
        self.modelsFetcher = modelsFetcher
        self.localeProvider = localeProvider
    }

    lazy var translationSettingsProvider: Middleware<AppState> = { state, action in
        guard let action = action as? TranslationSettingsViewAction else { return }
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

        default:
            break
        }
    }

    private func loadSettings(windowUUID: WindowUUID) async {
        let supported = await modelsFetcher.fetchSupportedTargetLanguages()
        let codes = manager.preferredLanguages(supportedTargetLanguages: supported)
        let isEnabled = prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
        let preferred = buildLanguageDetails(from: codes)
        store.dispatch(TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: isEnabled,
            preferredLanguages: preferred,
            supportedLanguages: supported,
            windowUUID: windowUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        ))
    }

    private func buildLanguageDetails(from codes: [String]) -> [PreferredLanguageDetails] {
        let deviceCode = localeProvider.current.languageCode ?? ""
        return codes.map { code in
            let native = Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
            let localized = localeProvider.current.localizedString(forLanguageCode: code) ?? code
            let isDeviceLanguage = code == deviceCode && code == codes.first
            let subtitle: String? = isDeviceLanguage
                ? .Settings.Translation.PreferredLanguages.DeviceLanguage
                : (native == localized ? nil : localized)
            return PreferredLanguageDetails(code: code, mainText: native, subtitleText: subtitle)
        }
    }
}

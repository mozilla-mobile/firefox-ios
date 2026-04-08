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

    private var isAutoTranslateEnabled: Bool {
        prefs.boolForKey(PrefsKeys.Settings.translationAutoTranslate) ?? false
    }

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
        self.handleAction(action, state: state)
    }

    private func handleAction(_ action: TranslationSettingsViewAction, state: AppState) {
        let translationState = state.componentState(
            TranslationSettingsState.self,
            for: .translationSettings,
            window: action.windowUUID
        )

        switch action.actionType {
        case TranslationSettingsViewActionType.viewDidLoad:
            let isTranslationsEnabled = prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
            let isAutoTranslateEnabled = prefs.boolForKey(PrefsKeys.Settings.translationAutoTranslate) ?? false
            store.dispatch(TranslationSettingsMiddlewareAction(
                isTranslationsEnabled: isTranslationsEnabled,
                isAutoTranslateEnabled: isAutoTranslateEnabled,
                windowUUID: action.windowUUID,
                actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
            ))
            Task { await self.loadSettings(windowUUID: action.windowUUID) }

        case TranslationSettingsViewActionType.toggleTranslationsEnabled:
            let current = prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
            let newValue = !current
            prefs.setBool(newValue, forKey: PrefsKeys.Settings.translationsFeature)
            SettingsTelemetry().changedSetting(
                PrefsKeys.Settings.translationsFeature,
                to: "\(newValue)",
                from: "\(current)"
            )
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

        case TranslationSettingsViewActionType.toggleAutoTranslate:
            let newValue = !isAutoTranslateEnabled
            prefs.setBool(newValue, forKey: PrefsKeys.Settings.translationAutoTranslate)
            SettingsTelemetry().changedSetting(
                PrefsKeys.Settings.translationAutoTranslate,
                to: "\(newValue)",
                from: "\(!newValue)"
            )
            store.dispatch(TranslationSettingsMiddlewareAction(
                isAutoTranslateEnabled: newValue,
                windowUUID: action.windowUUID,
                actionType: TranslationSettingsMiddlewareActionType.didUpdateSettings
            ))

        case TranslationSettingsViewActionType.addLanguage:
            guard let code = action.languageCode else { break }
            let updated = manager.addLanguage(code)
            let preferred = buildLanguageDetails(from: updated)
            let supported = translationState?.supportedLanguages ?? []
            store.dispatch(TranslationSettingsMiddlewareAction(
                preferredLanguages: preferred,
                availableLanguages: buildAvailableLanguages(preferred: updated, supported: supported),
                windowUUID: action.windowUUID,
                actionType: TranslationSettingsMiddlewareActionType.didUpdateSettings
            ))

        case TranslationSettingsViewActionType.saveLanguages:
            guard let languages = action.languages else { break }
            manager.save(languages: languages)
            let preferred = buildLanguageDetails(from: languages)
            let supported = translationState?.supportedLanguages ?? []
            store.dispatch(TranslationSettingsMiddlewareAction(
                preferredLanguages: preferred,
                availableLanguages: buildAvailableLanguages(preferred: languages, supported: supported),
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
        let isAutoTranslateEnabled = prefs.boolForKey(PrefsKeys.Settings.translationAutoTranslate) ?? false
        let preferred = buildLanguageDetails(from: codes)
        let available = buildAvailableLanguages(preferred: codes, supported: supported)
        store.dispatch(TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: isEnabled,
            isAutoTranslateEnabled: isAutoTranslateEnabled,
            preferredLanguages: preferred,
            supportedLanguages: supported,
            availableLanguages: available,
            windowUUID: windowUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        ))
    }

    private func buildAvailableLanguages(preferred: [String], supported: [String]) -> [String] {
        let preferredSet = Set(preferred)
        return supported
            .filter { !preferredSet.contains($0) }
            .sorted { [localeProvider] lhs, rhs in
                let lhsName = localeProvider.nativeLanguageName(for: lhs)
                let rhsName = localeProvider.nativeLanguageName(for: rhs)
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }
    }

    private func buildLanguageDetails(from codes: [String]) -> [PreferredLanguageDetails] {
        let deviceCode = localeProvider.current.languageCode ?? ""
        return codes.map { code in
            let native = localeProvider.nativeLanguageName(for: code)
            let localized = localeProvider.localizedLanguageName(for: code)
            let isDeviceLanguage = code == deviceCode
            let subtitle: String? = isDeviceLanguage
                ? .Settings.Translation.PreferredLanguages.DeviceLanguage
                : (native == localized ? nil : localized)
            return PreferredLanguageDetails(code: code, mainText: native, subtitleText: subtitle)
        }
    }
}

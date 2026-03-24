// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct PreferredLanguageDetails: Equatable, Hashable {
    let code: String
    let mainText: String
    let subtitleText: String?
}

struct TranslationSettingsState: ScreenState, Equatable {
    var isTranslationsEnabled: Bool
    var preferredLanguages: [PreferredLanguageDetails]
    var supportedLanguages: [String]
    var availableLanguages: [String]
    var windowUUID: WindowUUID

    init(appState: AppState, uuid: WindowUUID) {
        guard let state = appState.componentState(
            TranslationSettingsState.self,
            for: .translationSettings,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }
        self.init(
            windowUUID: state.windowUUID,
            isTranslationsEnabled: state.isTranslationsEnabled,
            preferredLanguages: state.preferredLanguages,
            supportedLanguages: state.supportedLanguages,
            availableLanguages: state.availableLanguages
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            isTranslationsEnabled: true,
            preferredLanguages: [],
            supportedLanguages: [],
            availableLanguages: []
        )
    }

    init(windowUUID: WindowUUID,
         isTranslationsEnabled: Bool,
         preferredLanguages: [PreferredLanguageDetails],
         supportedLanguages: [String],
         availableLanguages: [String] = []) {
        self.windowUUID = windowUUID
        self.isTranslationsEnabled = isTranslationsEnabled
        self.preferredLanguages = preferredLanguages
        self.supportedLanguages = supportedLanguages
        self.availableLanguages = availableLanguages
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
              let action = action as? TranslationSettingsMiddlewareAction else {
            return defaultState(from: state)
        }
        switch action.actionType {
        case TranslationSettingsMiddlewareActionType.didLoadSettings,
             TranslationSettingsMiddlewareActionType.didUpdateSettings:
            return TranslationSettingsState(
                windowUUID: state.windowUUID,
                isTranslationsEnabled: action.isTranslationsEnabled ?? state.isTranslationsEnabled,
                preferredLanguages: action.preferredLanguages ?? state.preferredLanguages,
                supportedLanguages: action.supportedLanguages ?? state.supportedLanguages,
                availableLanguages: action.availableLanguages ?? state.availableLanguages
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: TranslationSettingsState) -> TranslationSettingsState {
        return TranslationSettingsState(
            windowUUID: state.windowUUID,
            isTranslationsEnabled: state.isTranslationsEnabled,
            preferredLanguages: state.preferredLanguages,
            supportedLanguages: state.supportedLanguages,
            availableLanguages: state.availableLanguages
        )
    }

    static func == (lhs: TranslationSettingsState, rhs: TranslationSettingsState) -> Bool {
        return lhs.isTranslationsEnabled == rhs.isTranslationsEnabled
            && lhs.preferredLanguages == rhs.preferredLanguages
            && lhs.supportedLanguages == rhs.supportedLanguages
            && lhs.availableLanguages == rhs.availableLanguages
    }
}

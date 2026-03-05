// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TranslationSettingsState: ScreenState, Equatable {
    var isTranslationsEnabled: Bool
    var isAutoTranslateEnabled: Bool
    var preferredLanguages: [String]
    var supportedLanguages: [String]
    var windowUUID: WindowUUID

    init(appState: AppState, uuid: WindowUUID) {
        guard let state = appState.screenState(
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
            isAutoTranslateEnabled: state.isAutoTranslateEnabled,
            preferredLanguages: state.preferredLanguages,
            supportedLanguages: state.supportedLanguages
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            isTranslationsEnabled: true,
            isAutoTranslateEnabled: false,
            preferredLanguages: [],
            supportedLanguages: []
        )
    }

    init(windowUUID: WindowUUID,
         isTranslationsEnabled: Bool,
         isAutoTranslateEnabled: Bool,
         preferredLanguages: [String],
         supportedLanguages: [String]) {
        self.windowUUID = windowUUID
        self.isTranslationsEnabled = isTranslationsEnabled
        self.isAutoTranslateEnabled = isAutoTranslateEnabled
        self.preferredLanguages = preferredLanguages
        self.supportedLanguages = supportedLanguages
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
                isAutoTranslateEnabled: action.isAutoTranslateEnabled ?? state.isAutoTranslateEnabled,
                preferredLanguages: action.preferredLanguages ?? state.preferredLanguages,
                supportedLanguages: action.supportedLanguages ?? state.supportedLanguages
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: TranslationSettingsState) -> TranslationSettingsState {
        return TranslationSettingsState(
            windowUUID: state.windowUUID,
            isTranslationsEnabled: state.isTranslationsEnabled,
            isAutoTranslateEnabled: state.isAutoTranslateEnabled,
            preferredLanguages: state.preferredLanguages,
            supportedLanguages: state.supportedLanguages
        )
    }

    static func == (lhs: TranslationSettingsState, rhs: TranslationSettingsState) -> Bool {
        return lhs.isTranslationsEnabled == rhs.isTranslationsEnabled
            && lhs.isAutoTranslateEnabled == rhs.isAutoTranslateEnabled
            && lhs.preferredLanguages == rhs.preferredLanguages
            && lhs.supportedLanguages == rhs.supportedLanguages
    }
}

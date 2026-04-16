// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux

struct PreferredLanguageDetails: Equatable, Hashable {
    let code: String
    let mainText: String
    let subtitleText: String?
    let isDeviceLanguage: Bool

    init(code: String, mainText: String, subtitleText: String?, isDeviceLanguage: Bool = false) {
        self.code = code
        self.mainText = mainText
        self.subtitleText = subtitleText
        self.isDeviceLanguage = isDeviceLanguage
    }
}

@CopyWithUpdates
struct TranslationSettingsState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var isTranslationsEnabled: Bool
    var isAutoTranslateEnabled: Bool
    var isEditing: Bool
    var pendingLanguages: [PreferredLanguageDetails]?
    var preferredLanguages: [PreferredLanguageDetails]
    var supportedLanguages: [String]
    var availableLanguages: [String]

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
            isAutoTranslateEnabled: state.isAutoTranslateEnabled,
            isEditing: state.isEditing,
            pendingLanguages: state.pendingLanguages,
            preferredLanguages: state.preferredLanguages,
            supportedLanguages: state.supportedLanguages,
            availableLanguages: state.availableLanguages
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            isTranslationsEnabled: true,
            isAutoTranslateEnabled: false,
            isEditing: false,
            pendingLanguages: nil,
            preferredLanguages: [],
            supportedLanguages: [],
            availableLanguages: []
        )
    }

    init(windowUUID: WindowUUID,
         isTranslationsEnabled: Bool,
         isAutoTranslateEnabled: Bool = false,
         isEditing: Bool = false,
         pendingLanguages: [PreferredLanguageDetails]? = nil,
         preferredLanguages: [PreferredLanguageDetails],
         supportedLanguages: [String],
         availableLanguages: [String] = []) {
        self.windowUUID = windowUUID
        self.isTranslationsEnabled = isTranslationsEnabled
        self.isAutoTranslateEnabled = isAutoTranslateEnabled
        self.isEditing = isEditing
        self.pendingLanguages = pendingLanguages
        self.preferredLanguages = preferredLanguages
        self.supportedLanguages = supportedLanguages
        self.availableLanguages = availableLanguages
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }
        if let action = action as? TranslationSettingsMiddlewareAction {
            return reduceMiddlewareAction(state: state, action: action)
        }
        if let action = action as? TranslationSettingsViewAction {
            return reduceViewAction(state: state, action: action)
        }
        return defaultState(from: state)
    }

    private static func reduceMiddlewareAction(
        state: TranslationSettingsState,
        action: TranslationSettingsMiddlewareAction
    ) -> TranslationSettingsState {
        switch action.actionType {
        case TranslationSettingsMiddlewareActionType.didLoadSettings,
             TranslationSettingsMiddlewareActionType.didUpdateSettings:
            return state.copyWithUpdates(
                isTranslationsEnabled: action.isTranslationsEnabled ?? state.isTranslationsEnabled,
                isAutoTranslateEnabled: action.isAutoTranslateEnabled ?? state.isAutoTranslateEnabled,
                preferredLanguages: action.preferredLanguages ?? state.preferredLanguages,
                supportedLanguages: action.supportedLanguages ?? state.supportedLanguages,
                availableLanguages: action.availableLanguages ?? state.availableLanguages
            )
        default:
            return defaultState(from: state)
        }
    }

    private static func reduceViewAction(
        state: TranslationSettingsState,
        action: TranslationSettingsViewAction
    ) -> TranslationSettingsState {
        switch action.actionType {
        case TranslationSettingsViewActionType.enterEditMode:
            return state.copyWithUpdates(
                isEditing: true,
                pendingLanguages: state.preferredLanguages
            )
        case TranslationSettingsViewActionType.cancelEditMode:
            return state.copyWithUpdates(
                isEditing: false,
                pendingLanguages: nil,
            )
        case TranslationSettingsViewActionType.reorderLanguages:
            return state.copyWithUpdates(
                pendingLanguages: action.pendingLanguages,
            )
        case TranslationSettingsViewActionType.removeLanguage:
            guard let code = action.languageCode else { return defaultState(from: state) }
            var pending = state.pendingLanguages ?? state.preferredLanguages
            pending.removeAll { $0.code == code }
            return state.copyWithUpdates(
                pendingLanguages: pending,
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: TranslationSettingsState) -> TranslationSettingsState {
        return state.copyWithUpdates()
    }

    static func == (lhs: TranslationSettingsState, rhs: TranslationSettingsState) -> Bool {
        return lhs.isTranslationsEnabled == rhs.isTranslationsEnabled
            && lhs.isAutoTranslateEnabled == rhs.isAutoTranslateEnabled
            && lhs.isEditing == rhs.isEditing
            && lhs.pendingLanguages == rhs.pendingLanguages
            && lhs.preferredLanguages == rhs.preferredLanguages
            && lhs.supportedLanguages == rhs.supportedLanguages
            && lhs.availableLanguages == rhs.availableLanguages
    }
}

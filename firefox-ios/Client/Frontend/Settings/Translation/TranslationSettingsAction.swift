// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TranslationSettingsViewAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let languageCode: String?

    init(languageCode: String? = nil, windowUUID: WindowUUID, actionType: ActionType) {
        self.languageCode = languageCode
        self.windowUUID = windowUUID
        self.actionType = actionType
    }
}

struct TranslationSettingsMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let isTranslationsEnabled: Bool?
    let preferredLanguages: [PreferredLanguageDetails]?
    let supportedLanguages: [String]?

    init(isTranslationsEnabled: Bool? = nil,
         preferredLanguages: [PreferredLanguageDetails]? = nil,
         supportedLanguages: [String]? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.isTranslationsEnabled = isTranslationsEnabled
        self.preferredLanguages = preferredLanguages
        self.supportedLanguages = supportedLanguages
    }
}

enum TranslationSettingsViewActionType: ActionType {
    case viewDidLoad
    case toggleTranslationsEnabled
    case addLanguage
}

enum TranslationSettingsMiddlewareActionType: ActionType {
    case didLoadSettings
    case didUpdateSettings
}

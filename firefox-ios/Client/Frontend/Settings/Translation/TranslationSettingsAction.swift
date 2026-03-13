// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TranslationSettingsViewAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
}

struct TranslationSettingsMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let isTranslationsEnabled: Bool?
    let isAutoTranslateEnabled: Bool?
    let preferredLanguages: [String]?
    let supportedLanguages: [String]?

    init(isTranslationsEnabled: Bool? = nil,
         isAutoTranslateEnabled: Bool? = nil,
         preferredLanguages: [String]? = nil,
         supportedLanguages: [String]? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.isTranslationsEnabled = isTranslationsEnabled
        self.isAutoTranslateEnabled = isAutoTranslateEnabled
        self.preferredLanguages = preferredLanguages
        self.supportedLanguages = supportedLanguages
    }
}

enum TranslationSettingsViewActionType: ActionType {
    case viewDidLoad
    case toggleTranslationsEnabled
}

enum TranslationSettingsMiddlewareActionType: ActionType {
    case didLoadSettings
    case didUpdateSettings
}

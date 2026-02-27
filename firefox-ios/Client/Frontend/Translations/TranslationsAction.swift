// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TranslationsAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType

    init(
        windowUUID: WindowUUID,
        actionType: any ActionType,
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
    }
}

/// Carries the user-selected target language from the UIMenu picker.
/// `targetLanguage` is always known — the user just picked it from the menu.
struct TranslationLanguageSelectedAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let targetLanguage: String

    init(
        windowUUID: WindowUUID,
        targetLanguage: String,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.targetLanguage = targetLanguage
        self.actionType = actionType
    }
}

enum TranslationsActionType: ActionType {
    case didTapRetryFailedTranslation
    case didSelectTargetLanguage
}

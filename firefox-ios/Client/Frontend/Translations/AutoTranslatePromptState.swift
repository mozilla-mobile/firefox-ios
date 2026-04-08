// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct AutoTranslatePromptState: StateType, Equatable {
    var windowUUID: WindowUUID
    var showPrompt: Bool

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID, showPrompt: false)
    }

    init(windowUUID: WindowUUID, showPrompt: Bool) {
        self.windowUUID = windowUUID
        self.showPrompt = showPrompt
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case TranslationsActionType.showAutoTranslatePrompt:
            return AutoTranslatePromptState(windowUUID: state.windowUUID, showPrompt: true)
        case TranslationsActionType.didTapEnableAutoTranslate,
             TranslationsActionType.didDismissAutoTranslatePrompt:
            return AutoTranslatePromptState(windowUUID: state.windowUUID, showPrompt: false)
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: AutoTranslatePromptState) -> AutoTranslatePromptState {
        return AutoTranslatePromptState(windowUUID: state.windowUUID, showPrompt: state.showPrompt)
    }
}

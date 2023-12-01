// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct FeltPrivacyState: ScreenState, Equatable {
    var shouldHideSearchSuggestionView: Bool

    init(_ appState: BrowserViewControllerState) {
        self.init(shouldHideSearchSuggestionView: appState.feltPrivacyState.shouldHideSearchSuggestionView)
    }

    init() {
        self.init(shouldHideSearchSuggestionView: false)
    }

    init(shouldHideSearchSuggestionView: Bool) {
        self.shouldHideSearchSuggestionView = shouldHideSearchSuggestionView
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FeltPrivacyAction.privateModeUpdated(let privacyState):
            return FeltPrivacyState(shouldHideSearchSuggestionView: privacyState)
        default:
            return state
        }
    }
}

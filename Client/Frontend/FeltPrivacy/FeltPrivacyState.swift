// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct FeltPrivacyState: ScreenState, Equatable {
    var isInPrivateMode: Bool

    init(_ appState: BrowserViewControllerState) {
        self.init(isInPrivateMode: appState.feltPrivacyState.isInPrivateMode)
    }

    init() {
        self.init(isInPrivateMode: false)
    }

    init(isInPrivateMode: Bool) {
        self.isInPrivateMode = isInPrivateMode
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FeltPrivacyAction.privateModeUpdated(let privacyState):
            return FeltPrivacyState(isInPrivateMode: privacyState)
        default:
            return state
        }
    }
}

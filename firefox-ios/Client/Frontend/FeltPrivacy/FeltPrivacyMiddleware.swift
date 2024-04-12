// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Shared

class FeltPrivacyMiddleware {
    var privacyStateManager: ThemeManager

    init(privacyStateManager: ThemeManager = AppContainer.shared.resolve()) {
        self.privacyStateManager = privacyStateManager
    }

    lazy var privacyManagerProvider: Middleware<AppState> = { state, action in
        let uuid = action.windowUUID
        switch action {
        case PrivateModeUserAction.setPrivateModeTo(let context):
            let privateState = context.boolValue
            self.updateManagerWith(newState: privateState, for: uuid)
            let newContext = BoolValueContext(boolValue: privateState, windowUUID: uuid)
            store.dispatch(PrivateModeMiddlewareAction.privateModeUpdated(newContext))
        default:
            break
        }
    }

    // MARK: - Helper Functions
    private func updateManagerWith(newState: Bool, for window: UUID) {
        privacyStateManager.setPrivateTheme(isOn: newState, for: window)
    }
}

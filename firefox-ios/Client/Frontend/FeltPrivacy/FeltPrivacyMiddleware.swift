// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

// TODO: [8313] Middlewares are currently handling actions globally. Need updates for multi-window. Forthcoming.
class FeltPrivacyMiddleware {
    var privacyManager: FeltPrivacyManager

    init(privacyManager: FeltPrivacyManager = FeltPrivacyManager(isInPrivateMode: false)) {
        self.privacyManager = privacyManager
    }

    lazy var privacyManagerProvider: Middleware<AppState> = { state, action in
        let uuid = action.windowUUID
        switch action {
        case PrivateModeUserAction.setPrivateModeTo(let context):
            let privateState = context.boolValue
            self.updateManagerWith(newState: privateState)
            let newContext = BoolValueContext(boolValue: self.privacyManager.getPrivateModeState(), windowUUID: uuid)
            store.dispatch(PrivateModeMiddlewareAction.privateModeUpdated(newContext))
        default:
            break
        }
    }

    // MARK: - Helper Functions
    private func updateManagerWith(newState: Bool) {
        privacyManager.setPrivateModeState(to: newState)
    }
}

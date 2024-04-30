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
        guard let action = action as? PrivateModeAction else { return }
        switch action.actionType {
        case PrivateModeActionType.setPrivateModeTo:
            let privateState = action.isPrivate
            self.updateManagerWith(newState: action.isPrivate ?? false,
                                   for: action.windowUUID)
            let updateAction = PrivateModeAction(isPrivate: privateState,
                                                 windowUUID: action.windowUUID,
                                                 actionType: PrivateModeActionType.privateModeUpdated)
            store.dispatch(updateAction)
        default:
            break
        }
    }

    // MARK: - Helper Functions
    private func updateManagerWith(newState: Bool, for window: UUID) {
        privacyStateManager.setPrivateTheme(isOn: newState, for: window)
    }
}

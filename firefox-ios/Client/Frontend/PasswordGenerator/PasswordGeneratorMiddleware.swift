// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

final class PasswordGeneratorMiddleware: FeatureFlaggable {
    lazy var passwordGeneratorProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        guard let currentTab = (action as? PasswordGeneratorAction)?.currentTab else { return }
        switch action.actionType {
        case PasswordGeneratorActionType.showPasswordGenerator:
                self.showPasswordGenerator(tab: currentTab, windowUUID: windowUUID)
        default:
            break
        }
    }

    private func showPasswordGenerator(tab: Tab, windowUUID: WindowUUID) {
        // TODO - FXIOS-9660 Business Logic to be added (tab is a necessary part of future business logic)
        let newAction = PasswordGeneratorAction(
            windowUUID: windowUUID,
            actionType: PasswordGeneratorActionType.updateGeneratedPassword,
            password: "fjdisapfjio32iojds" // to be replaced
        )
        store.dispatch(newAction)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

final class PasswordGeneratorAction: Action {
    // Used in the middlwares
    let currentTab: Tab?

    // Used in some reducers
    let password: String?

    init(windowUUID: WindowUUID, actionType: any ActionType, currentTab: Tab? = nil, password: String? = nil) {
        self.currentTab = currentTab
        self.password = password
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum PasswordGeneratorActionType: ActionType {
    // User Actions
    case showPasswordGenerator
    case userTappedRefreshPassword
    case userTappedUsePassword
    case clearGeneratedPasswordForSite

    // Middleware Actions
    case updateGeneratedPassword
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import WebKit

struct PasswordGeneratorFrameContext: Equatable {
    let origin: String?
    let host: String?
    let scriptEvaluator: PasswordGeneratorScriptEvaluator?
    let frameInfo: WKFrameInfo?

    static func == (lhs: PasswordGeneratorFrameContext, rhs: PasswordGeneratorFrameContext) -> Bool {
        lhs.origin == rhs.origin &&
        lhs.host == rhs.host
    }
}

struct PasswordGeneratorAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType

    // Used in the middlewares
    let frameContext: PasswordGeneratorFrameContext?

    // Used in some reducers
    let password: String?

    init(windowUUID: WindowUUID,
         actionType: any ActionType,
         password: String? = nil,
         frameContext: PasswordGeneratorFrameContext? = nil) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.password = password
        self.frameContext = frameContext
    }
}

enum PasswordGeneratorActionType: ActionType {
    // User Actions
    case showPasswordGenerator
    case userTappedRefreshPassword
    case userTappedUsePassword
    case clearGeneratedPasswordForSite
    case hidePassword
    case showPassword

    // Middleware Actions
    case updateGeneratedPassword
}

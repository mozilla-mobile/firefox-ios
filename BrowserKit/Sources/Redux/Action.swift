// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Used to describe an action that can be dispatched by the redux store
open class Action {
    public var windowUUID: WindowUUID
    public var actionType: ActionType

    public init(windowUUID: WindowUUID, actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
    }

    func displayString() -> String {
        let className = String(describing: Self.self)
        return "\(className) \(actionType)"
    }
}

public protocol ActionType {}

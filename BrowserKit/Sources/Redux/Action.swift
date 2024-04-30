// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Used to describe an action that can be dispatched by the redux store
open class Action {
    public var windowUUID: UUID
    public var actionType: ActionType

    public init(windowUUID: UUID, actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
    }

    func displayString() -> String {
        let className = String(describing: Self.self)
        let actionName = String(describing: self).prefix(20)
        return "\(className).\(actionName)"
    }
}

public protocol ActionType {}

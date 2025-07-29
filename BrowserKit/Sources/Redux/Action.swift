// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Used to describe an action that can be dispatched by the redux store
public protocol Action: CustomDebugStringConvertible {
    var windowUUID: WindowUUID { get }
    var actionType: ActionType { get }
}

extension Action {
    func displayString() -> String {
        let className = String(describing: Self.self)
        return "\(className) \(actionType)"
    }

    public var debugDescription: String {
        let className = String(describing: type(of: self))
        return "<\(className)> Type: \(actionType) Window: \(windowUUID.uuidString.prefix(4))"
    }
}

public protocol ActionType: Sendable {}

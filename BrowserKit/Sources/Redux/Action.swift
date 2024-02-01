// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Are a declarative way of describing a state change. Actions don’t contain any code,
/// they are consumed by the store and forwarded to reducers. Are used to express intended
/// state changes. Actions include a context object that includes information about the
/// action, including a UUID for a particular window. If an Action is truly global in
/// nature or can't be associated with a UUID it can send either the UUID for the active
/// window (see `WindowManager.activeWindow`) or if needed `WindowUUID.unavailable`.
public protocol Action {
    var windowUUID: UUID { get }
}

extension Action {
    func displayString() -> String {
        let className = String(describing: Self.self)
        let actionName = String(describing: self).prefix(20)
        return "\(className).\(actionName)"
    }
}

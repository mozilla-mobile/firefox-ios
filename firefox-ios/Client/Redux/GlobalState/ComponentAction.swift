// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct ComponentAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let component: AppComponent
    /// Identifies the specific screen instance that owns this component. When set, add/remove and
    /// lookups are scoped to that instance, so a screen can only ever remove its own entry. Leave `nil`
    /// (the default) for screens that don't need per-instance ownership, they keep the original
    /// match-by-`(component, window)` behavior.
    let screenIdentity: UUID?

    init(windowUUID: WindowUUID,
         actionType: ActionType,
         component: AppComponent,
         screenIdentity: UUID? = nil) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.component = component
        self.screenIdentity = screenIdentity
    }
}

enum ComponentActionType: ActionType {
    case addComponent
    case removeComponent
}

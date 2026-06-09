// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

enum DismissalReason: Equatable {
    case user
    case deeplink
}

// Used for any view controllers that shouldn't be dismissed whenever we `popToViewController`
protocol PreventsDismissal: AnyObject {}

// Used for any view controllers that wants to be notified whenever they are dismissed by a `popToViewController`
protocol DismissalNotifiable: AnyObject {
    @MainActor
    func willBeDismissed(reason: DismissalReason)
}

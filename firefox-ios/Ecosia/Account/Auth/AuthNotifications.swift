// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Notification names for authentication state changes
extension Notification.Name {
    /// Posted when authentication state changes for any window
    /// UserInfo contains: windowUUID, authState, actionType
    public static let EcosiaAuthStateChanged = Notification.Name("EcosiaAuthStateChanged")

    /// Posted when user profile information is updated from Auth0
    /// This includes user name, email, and profile picture URL
    public static let EcosiaUserProfileUpdated = Notification.Name("EcosiaUserProfileUpdated")
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Avatar {
    public let url: String
    public let isDefault: Bool
}

public struct Profile {
    public let uid: String
    public let email: String
    public let avatar: Avatar?
    public let displayName: String?

    internal init(msg: MsgTypes_Profile) {
        uid = msg.uid
        email = msg.email
        avatar = msg.hasAvatar ? Avatar(url: msg.avatar, isDefault: msg.avatarDefault) : nil
        displayName = msg.hasDisplayName ? msg.displayName : nil
    }

    // For testing.
    internal init(uid: String, email: String, avatar: Avatar? = nil, displayName: String? = nil) {
        self.uid = uid
        self.email = email
        self.avatar = avatar
        self.displayName = displayName
    }
}

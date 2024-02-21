// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

struct Login: Hashable {
    var website: String
    var username: String

    init(website: String, username: String) {
        self.website = website
        self.username = username
    }

    init(encryptedLogin: EncryptedLogin) {
        self.website = encryptedLogin.hostname
        self.username = encryptedLogin.decryptedUsername
    }
}

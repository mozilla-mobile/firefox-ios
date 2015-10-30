/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ReadingListOAuthAuthAuthenticator: ReadingListAuthenticator {
    var token: String
    var headers: [String: String]

    init(token: String) {
        self.token = token
        self.headers = ["Authorization": "Bearer \(token)"]
    }
}
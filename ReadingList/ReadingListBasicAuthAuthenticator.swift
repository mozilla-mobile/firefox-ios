/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ReadingListBasicAuthAuthenticator: ReadingListAuthenticator {
    var headers: [String: String]

    init(username: String, password: String) {
        let credentials = "\(username):\(password)"
        let credentialsData = credentials.dataUsingEncoding(NSUTF8StringEncoding)!
        let encodedCredentials = credentialsData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
        self.headers = ["Authorization": "Basic \(encodedCredentials)"]
    }
}
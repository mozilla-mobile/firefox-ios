/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct SecureConnectionStatus {
    let url: URL
    let isSecureConnection: Bool
}

extension SecureConnectionStatus {
    var faviconURL: URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.path = "/favicon.ico"
        return components?.url
    }
}

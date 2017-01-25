/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension URLProtectionSpace {

    public func urlString() -> String {
        // If our host is empty, return nothing since it doesn't make sense to add the scheme or port.
        guard !host.isEmpty else {
            return ""
        }

        var urlString: String
        if let p = `protocol` {
            urlString = "\(p)://\(host)"
        } else {
            urlString = host
        }

        // Check for non-standard ports
        if port != 0 && port != 443 && port != 80 {
            urlString += ":\(port)"
        }

        return urlString
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension NSURLProtectionSpace {

    public func urlString() -> String {
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
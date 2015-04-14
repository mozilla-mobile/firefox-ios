/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

extension NSURL {
    public func withQueryParam(name: String, value: String) -> NSURL {
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)!
        let item = NSURLQueryItem(name: name, value: value)
        components.queryItems = (components.queryItems ?? []) + [item]
        return components.URL!
    }
}
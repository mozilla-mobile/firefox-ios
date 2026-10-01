// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Problem: Sites like amazon exist with .ca/.de and many other tlds. There's sometimes also prefixes like m. or mobile.
// in front of the domain. The bundled favicon doesn't support all of those domain formats, we need a
// standard way to retrieve.
// Solution: Favicons are stored as "amazon" instead of "amazon.com" or "facebook" instead of "m.facebook" in the
// bundle. This allows us to have favicons for every tld.
struct BundleDomainBuilder {
    func buildDomains(for siteURL: URL) -> [String] {
        let shortURL = siteURL.shortDisplayString
        let absoluteURL = siteURL.absoluteDisplayString.removingOccurrences(of: "\(siteURL.scheme ?? "")://")
        var domains = [shortURL, absoluteURL]

        if let baseDomain = siteURL.baseDomain {
            domains.append(baseDomain)
        }

        return domains
    }
}

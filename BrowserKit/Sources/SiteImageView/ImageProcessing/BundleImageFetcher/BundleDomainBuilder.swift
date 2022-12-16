// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

// TODO: Laurie - documentation
// Problem: Sites like amazon exist with .ca/.de and many other tlds.
// We sometimes also have prefix like m. or mobile. in front of the domain.
// Solution: They are stored as "amazon" instead of "amazon.com" this allows us to have favicons for every tld."
// Here, If the site is in the multiRegionDomain array look it up via its second level domain (amazon) instead
// of its baseDomain (amazon.com)
// TODO: Laurie - tests
struct BundleDomainBuilder {
    func buildDomains(for siteURL: URL) -> [String] {
        let shortURL = siteURL.shortDisplayString
        let absoluteURL = siteURL.absoluteDisplayString.remove("\(siteURL.scheme ?? "")://")
        var domains = [shortURL, absoluteURL]

        if let baseDomain = siteURL.baseDomain {
            domains.append(baseDomain)
        }

        return domains
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum PartnerWebsite: String, CaseIterable {
    case amazon
    case walmart
    case bestbuy

    var title: String {
        switch self {
        case .bestbuy: return "Best Buy"
        default: return self.rawValue.capitalized
        }
    }

    var orderWebsites: [String] {
        let currentPartnerWebsites = PartnerWebsite.allCases.map { $0.title }

        // make sure current website is first
        var websitesOrder = currentPartnerWebsites.filter { $0 != self.title }
        websitesOrder.insert(self.title, at: 0)

        return websitesOrder
    }

    init?(for siteName: String?) {
        guard let siteName = siteName, let partner = PartnerWebsite(rawValue: siteName) else {
            return nil
        }

        self = partner
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct BreachAlertsTestData {
    func breaches(forDomains domains: [String]) -> Set<BreachRecord> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let breachDate = dateFormatter.string(from: Date(timeIntervalSinceNow: 24 * 60 * 60))

        return Set(domains.map { domain in
            BreachRecord(name: domain,
                         title: domain,
                         domain: domain,
                         breachDate: breachDate,
                         description: "Mock breach alert")
        })
    }
}

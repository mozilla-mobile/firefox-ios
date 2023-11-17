// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension NumberFormatter {
    static func ecosiaCurrency(withoutEuroSymbol: Bool = false) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = withoutEuroSymbol ? "" : "€"
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        formatter.currencyGroupingSeparator = ","
        return formatter
    }
}

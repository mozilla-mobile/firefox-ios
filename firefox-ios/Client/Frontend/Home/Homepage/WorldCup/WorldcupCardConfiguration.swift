// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Configuration data for a generic countdown promo card.
/// Swap any field to produce a different card variant.
struct WorldcupCardConfiguration: Hashable {
    let title: String
    let targetDate: Date
    let ctaButtonLabel: String
    let heroImage: UIImage?

    static func == (lhs: WorldcupCardConfiguration, rhs: WorldcupCardConfiguration) -> Bool {
        lhs.title == rhs.title
            && lhs.targetDate == rhs.targetDate
            && lhs.ctaButtonLabel == rhs.ctaButtonLabel
            && lhs.heroImage === rhs.heroImage
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(targetDate)
        hasher.combine(ctaButtonLabel)
    }
}

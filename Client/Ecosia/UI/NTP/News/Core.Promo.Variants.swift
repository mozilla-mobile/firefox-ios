// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

extension Core.Promo {
    static func current(for user: User, using goodall: Goodall) -> Promo? {
        guard let variant = Promo.variant(for: .shared, using: .shared) else { return nil }
        switch variant {
        case .control:
            return .treeStore
        case .test:
            return .treeCard
        }
    }

    static var treeStore: Core.Promo {
        .init(text: .localized(.buyTrees),
              image: "treeStore",
              icon: "treestore_logo",
              highlight:nil,
              description: "Tree Store",
              targetUrl: URL(string: "https://plant.ecosia.org/?utm_source=referral&utm_medium=product&utm_campaign=q4e1_ios_app_ntp")!,
              trackingName: "ios_tree_store")
    }

    static var treeCard: Core.Promo {
        .init(text: .localized(.plantTreesAndEarn),
              image: "treeCard",
              icon: "treecard_logo",
              highlight: .localized(.sponsored) + " ·",
              description: "Treecard",
              targetUrl: URL(string: "https://www.treecard.org/ecosia")!,
              trackingName: "ios_tree_card")
    }
}

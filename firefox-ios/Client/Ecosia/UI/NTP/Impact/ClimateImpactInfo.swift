// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum ClimateImpactInfo: Equatable {
    case referral(value: Int)
    case totalTrees(value: Int)
    case totalInvested(value: Int)

    var title: String {
        switch self {
        case .referral(let value):
            return "\(value)"
        case .totalTrees(let value):
            return NumberFormatter.ecosiaCurrency(withoutEuroSymbol: true)
                .string(from: .init(integerLiteral: value)) ?? ""
        case .totalInvested(let value):
            return NumberFormatter.ecosiaCurrency()
                .string(from: .init(integerLiteral: value)) ?? ""
        }
    }

    var subtitle: String {
        switch self {
        case .referral(let value):
            return .localizedPlural(.acceptedInvites, num: value)
        case .totalTrees:
            return .localized(.treesPlantedByEcosia)
        case .totalInvested:
            return .localized(.dedicatedToClimateAction)
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .referral(let value):
            return accessiblityLabelTreesPlanted(value: value) + .localizedPlural(.acceptedInvites, num: value)
        case .totalTrees(let value):
            return value.spelledOutString + " " + .localized(.treesPlantedByEcosia)
        case .totalInvested(let value):
            return value.spelledOutString + " " + .localized(.dedicatedToClimateAction)
        }
    }

    var accessibilityIdentifier: String? {
        switch self {
        case .referral:
            "friends_and_trees_invites_counter"
        case .totalTrees:
            "total_trees_count"
        case .totalInvested:
            "total_invested_count"
        }
    }

    var image: UIImage? {
        switch self {
        case .referral:
            return .init(named: "referral", in: .ecosia, with: nil)
        case .totalTrees:
            return .init(named: "tree", in: .ecosia, with: nil)
        case .totalInvested:
            return .init(named: "banknote", in: .ecosia, with: nil)
        }
    }

    var buttonTitle: String? {
        switch self {
        case .referral:
            return .localized(.inviteFriends)
        case .totalTrees, .totalInvested:
            return nil
        }
    }

    var accessibilityHint: String? {
        switch self {
        case .referral:
            return .localized(.inviteFriends)
        case .totalTrees, .totalInvested:
            return nil
        }
    }

    var imageAccessibilityIdentifier: String? {
        switch self {
        case .referral:
            "referral_image"
        case .totalTrees:
            "total_trees_image"
        case .totalInvested:
            "total_invested_image"
        }
    }

    /// Created to be used for comparison without taking the associated types arguments into consideration.
    var rawValue: Int {
        switch self {
        case .referral:
            return 0
        case .totalTrees:
            return 1
        case .totalInvested:
            return 2
        }
    }

    private func accessiblityLabelTreesPlanted(value: Int) -> String {
        value.spelledOutString + " " + .localizedPlural(.treesPlanted, num: value) + ";"
    }
}

extension Int {
    fileprivate var spelledOutString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter.string(from: .init(integerLiteral: self)) ?? ""
    }
}

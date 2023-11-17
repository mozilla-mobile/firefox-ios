// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

enum ClimateImpactInfo: Equatable {
    case search(value: Int, searches: Int)
    case referral(value: Int, invites: Int)
    case totalTrees(value: Int)
    case totalInvested(value: Int)
    
    var title: String {
        switch self {
        case .search(let value, _):
            return "\(value)"
        case .referral(let value, _):
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
        case .search(_, let searches):
            return .localizedPlural(.searches, num: searches)
        case .referral(_, let invites):
            return .localizedPlural(.friendInvitesPlural, num: invites)
        case .totalTrees:
            return .localized(.treesPlantedByTheCommunity)
        case .totalInvested:
            return .localized(.investedIntoClimateAction)
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .search(let value, let searches):
            return accessiblityLabelTreesPlanted(value: value) + .localizedPlural(.searches, num: searches)
        case .referral(let value, let invites):
            return accessiblityLabelTreesPlanted(value: value) + .localizedPlural(.friendInvitesPlural, num: invites)
        case .totalTrees(let value):
            return value.spelledOutString + " " + .localized(.treesPlantedByTheCommunity)
        case .totalInvested(let value):
            return value.spelledOutString + " " + .localized(.investedIntoClimateAction)
        }
    }
    
    var image: UIImage? {
        switch self {
        case .search:
            return .init(named: "yourImpact")
        case .referral:
            return .init(named: "groupYourImpact")
        case .totalTrees:
            return .init(named: "hand")
        case .totalInvested:
            return .init(named: "financialReports")
        }
    }
    
    var buttonTitle: String? {
        switch self {
        case .search:
            return .localized(.howItWorks)
        case .referral:
            return .localized(.inviteFriends)
        case .totalTrees, .totalInvested:
            return nil
        }
    }
    
    var accessibilityHint: String? {
        switch self {
        case .search:
            return .localized(.howItWorks)
        case .referral:
            return .localized(.inviteFriends)
        case .totalTrees, .totalInvested:
            return nil
        }
    }
    
    var progressIndicatorValue: Double? {
        switch self {
        case .search:
            return User.shared.progress
        case .referral, .totalInvested, .totalTrees:
            return nil
        }
    }
    
    /// Created to be used for comparison without taking the associated types arguments into consideration.
    var rawValue: Int {
        switch self {
        case .search:
            return 0
        case .referral:
            return 1
        case .totalTrees:
            return 2
        case .totalInvested:
            return 3
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

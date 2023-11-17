/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core

extension NTPTooltip {
    enum Highlight {
        case gotClaimed
        case successfulInvite
        case referralSpotlight
        case collectiveImpactIntro

        var text: String {
            switch self {
            case .gotClaimed:
                return .localized(.youveContributed)
            case .successfulInvite:
                let highlight: String
                let count = User.shared.referrals.newClaims
                if  count <= 1 {
                    highlight = .localized(.referralAccepted)
                } else {
                    highlight = .init(format: .localized(.referralsAccepted), "\(count)", "\(count)")
                }
                return highlight
            case .referralSpotlight:
                return .localized(.togetherWeCan)
            case .collectiveImpactIntro:
                return .localized(.seeTheCollectiveImpact)
            }
        }

    }

    class func highlight(for user: Core.User = User.shared,
                         isInPromoTest: Bool = DefaultBrowserExperiment.isInPromoTest()) -> NTPTooltip.Highlight? {
        // on first start, when we show the default browser promo, no highlight should be shown
        guard !user.firstTime || isInPromoTest else { return nil }

        if user.referrals.isNewClaim {
            return .gotClaimed
        }

        if user.referrals.newClaims > 0 {
            return .successfulInvite
        }

        if user.showsReferralSpotlight {
            return .referralSpotlight
        }

        if user.shouldShowImpactIntro {
            return .collectiveImpactIntro
        }

        return nil
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core

extension NTPTooltip {
    enum Highlight {
        case counterIntro
        case gotClaimed
        case successfulInvite
        case referralSpotlight

        var text: String {
            switch self {
            case .counterIntro:
                return .localized(.trackYourProgress)
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
            }
        }

    }

    class func highlight(for user: Core.User) -> NTPTooltip.Highlight? {
        guard !user.firstTime else { return nil }

        if user.referrals.isNewClaim {
            return .gotClaimed
        }

        if user.referrals.newClaims > 0 {
            return .successfulInvite
        }

        if user.showsReferralSpotlight {
            return .referralSpotlight
        }

        if user.showsCounterIntro {
            return .counterIntro
        }

        return nil
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

extension WelcomeTour {

    enum Step {
        case green
        case profit
        case action
        case transparent

        static var all: [Step] {
            [.green, .profit, .action, .transparent]
        }

        var title: String {
            switch self {
            case .green:
                return .localized(.grennestWayToSearch)
            case .profit:
                return .localized(.hundredPercentOfProfits)
            case .action:
                return .localized(.collectiveAction)
            case .transparent:
                return .localized(.realResults)
            }
        }
        var text: String {
            switch self {
            case .green:
                return .localized(.planetFriendlySearch)
            case .profit:
                return .localized(.weUseAllOurProfits)
            case .action:
                return .localized(.join15Million)
            case .transparent:
                return .localized(.shownExactlyHowMuch)
            }
        }
        var background: Background {
            switch self {
            case .green:
                return .init(image: "tour1")
            case .profit:
                return .init(image: "tour2")
            case .action:
                return .init(image: "tour3", color: UIColor(rgb: 0x668A7A))
            case .transparent:
                return .init(image: "tour4")
            }
        }
        var accessibleDescriptionKey: String.Key {
            switch self {
            case .green:
                return .onboardingIllustrationTour1
            case .profit:
                return .onboardingIllustrationTour2
            case .action:
                return .onboardingIllustrationTour3
            case .transparent:
                return .onboardingIllustrationTour4
            }
        }
        var content: UIView? {
            let view: UIView?
            switch self {
            case .green:
                view = WelcomeTourGreen()
            case .profit:
                view = WelcomeTourProfit()
            case .action:
                view = WelcomeTourAction()
            case .transparent:
                view = WelcomeTourTransparent()
            }
            view?.isAccessibilityElement = true
            view?.accessibilityLabel = .localized(accessibleDescriptionKey)
            return view
        }
        var analyticsValue: Analytics.Property.OnboardingPage {
            switch self {
            case .profit:
                return .profits
            case .action:
                return .action
            case .green:
                return .greenSearch
            case .transparent:
                return .transparentFinances
            }
        }
    }
}

extension WelcomeTour.Step {

    final class Background {
        let image: String
        let color: UIColor?

        init(image: String, color: UIColor? = nil) {
            self.image = image
            self.color = color
        }
    }
}

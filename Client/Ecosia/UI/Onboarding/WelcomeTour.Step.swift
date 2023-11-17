/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

extension WelcomeTour {

    enum Step {
        case planet
        case green
        case profit
        case action
        case trees
        case transparent

        static var all: [Step] {
            if Unleash.isEnabled(.incentiveRestrictedSearch) {
                return [.green, .profit, .action, .transparent]
            } else {
                return [.planet, .profit, .action, .trees]
            }
            
        }
        
        var title: String {
            switch self {
            case .planet:
                return .localized(.aBetterPlanet)
            case .green:
                return .localized(.grennestWayToSearch)
            case .profit:
                return .localized(.hundredPercentOfProfits)
            case .action:
                return .localized(.collectiveAction)
            case .trees:
                return .localized(.weWantTrees)
            case .transparent:
                return .localized(.realResults)
            }
        }
        var text: String {
            switch self {
            case .planet:
                return .localized(.searchTheWeb)
            case .green:
                return .localized(.planetFriendlySearch)
            case .profit:
                return .localized(.weUseAllOurProfits)
            case .action:
                return .localized(.join15Million)
            case .trees:
                return .localized(.weDontCreateAProfile)
            case .transparent:
                return .localized(.shownExactlyHowMuch)
            }
        }
        var background: Background {
            switch self {
            case .green ,.planet:
                return .init(image: "tour1")
            case .profit:
                return .init(image: "tour2")
            case .action:
                return .init(image: "tour3", color: UIColor(rgb: 0x668A7A))
            case .trees:
                return .init(image: "tour4")
            case .transparent:
                return .init(image: "tour4-alternative")
            }
        }
        var accessibleDescriptionKey: String.Key {
            switch self {
            case .planet:
                return .onboardingIllustrationTour1
            case .green:
                return .onboardingIllustrationTour1Alternative
            case .profit:
                return .onboardingIllustrationTour2
            case .action:
                return .onboardingIllustrationTour3
            case .trees:
                return .onboardingIllustrationTour4
            case .transparent:
                return .onboardingIllustrationTour4Alternative
            }
        }
        var content: UIView? {
            let view: UIView?
            switch self {
            case .planet:
                view = WelcomeTourGreen(isCounterEnabled: true)
            case .green:
                view = WelcomeTourGreen()
            case .profit:
                view = WelcomeTourProfit()
            case .action:
                view = WelcomeTourAction()
            case .trees:
                view = nil
            case .transparent:
                view = WelcomeTourTransparent()
            }
            view?.isAccessibilityElement = true
            view?.accessibilityLabel = .localized(accessibleDescriptionKey)
            return view
        }
        var analyticsValue: Analytics.Property.OnboardingPage {
            switch self {
            case .planet:
                return .search
            case .profit:
                return .profits
            case .action:
                return .action
            case .trees:
                return .privacy
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

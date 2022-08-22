// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol OnboardingViewControllerProtocol {
    var didFinishFlow: (() -> Void)? { get }

    func getNextOnboardingCard(index: Int, goForward: Bool) -> OnboardingCardViewController?
    func moveToNextPage(cardType: IntroViewModel.InformationCards)
    func getCardIndex(viewController: OnboardingCardViewController) -> Int?
    func showNextPage(_ cardType: IntroViewModel.InformationCards)
}

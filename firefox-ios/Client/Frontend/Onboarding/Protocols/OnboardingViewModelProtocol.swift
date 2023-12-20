// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingViewModelProtocol {
    var availableCards: [OnboardingCardViewController] { get }
    var isDismissable: Bool { get }
    var profile: Profile { get }
    var telemetryUtility: OnboardingTelemetryProtocol { get }

    func setupViewControllerDelegates(with delegate: OnboardingCardDelegate)
}

extension OnboardingViewModelProtocol {
    func getNextIndex(currentIndex: Int, goForward: Bool) -> Int? {
        if goForward && currentIndex + 1 < availableCards.count {
            return currentIndex + 1
        }

        if !goForward && currentIndex > 0 {
            return currentIndex - 1
        }

        return nil
    }
}

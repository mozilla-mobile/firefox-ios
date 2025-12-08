// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol OnboardingViewModelProtocol {
    var availableCards: [OnboardingCardViewController<OnboardingKitCardInfoModel>] { get }
    var isDismissible: Bool { get }
    var profile: Profile { get }
    var telemetryUtility: OnboardingTelemetryProtocol { get }

    @MainActor
    func setupViewControllerDelegates(with delegate: OnboardingCardDelegate, for window: WindowUUID)
}

extension OnboardingViewModelProtocol {
    func getNextIndexFrom(
        currentIndex: Int,
        numberOfCardsToMove: Int,
        goForward: Bool
    ) -> Int? {
        if goForward && currentIndex + numberOfCardsToMove < availableCards.count {
            return currentIndex + numberOfCardsToMove
        }

        if !goForward &&
            currentIndex > 0 &&
            currentIndex - numberOfCardsToMove >= 0 {
            return currentIndex - numberOfCardsToMove
        }

        return nil
    }
}

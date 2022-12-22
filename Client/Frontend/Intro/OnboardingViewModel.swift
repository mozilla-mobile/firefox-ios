// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingViewModelProtocol {
    var enabledCards: [IntroViewModel.InformationCards] { get }
    var isFeatureEnabled: Bool { get }

    func getCardViewModel(cardType: IntroViewModel.InformationCards) -> OnboardingCardProtocol?
    func getInfoModel(cardType: IntroViewModel.InformationCards) -> OnboardingModelProtocol?
}

extension OnboardingViewModelProtocol {
    func getNextIndex(currentIndex: Int, goForward: Bool) -> Int? {
        if goForward && currentIndex + 1 < enabledCards.count {
            return currentIndex + 1
        }

        if !goForward && currentIndex > 0 {
            return currentIndex - 1
        }

        return nil
    }

    func getCardViewModel(cardType: IntroViewModel.InformationCards) -> OnboardingCardProtocol? {
        guard let infoModel = getInfoModel(cardType: cardType) else { return nil }

        return OnboardingCardViewModel(cardType: cardType,
                                       infoModel: infoModel,
                                       isFeatureEnabled: isFeatureEnabled)
    }
}

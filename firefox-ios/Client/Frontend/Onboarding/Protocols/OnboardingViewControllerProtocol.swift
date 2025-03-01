// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingViewControllerProtocol {
    var pageController: UIPageViewController { get }
    var pageControl: UIPageControl { get }
    var viewModel: OnboardingViewModelProtocol { get }
    var didFinishFlow: (() -> Void)? { get }

    func canMoveForward(numberOfPages: Int, from cardNamed: String) -> Bool
    func moveForward(numberOfPages: Int, from cardNamed: String)
    func getNextOnboardingCard(
        currentIndex: Int,
        numberOfCardsToMove: Int,
        goForward: Bool
    ) -> OnboardingCardViewController?

    func getCardIndex(viewController: OnboardingCardViewController) -> Int?
}

extension OnboardingViewControllerProtocol {
    func getNextOnboardingCard(
        currentIndex: Int,
        numberOfCardsToMove: Int,
        goForward: Bool
    ) -> OnboardingCardViewController? {
        guard let nextIndex = viewModel.getNextIndexFrom(
            currentIndex: currentIndex,
            numberOfCardsToMove: numberOfCardsToMove,
            goForward: goForward
        ) else { return nil }

        return viewModel.availableCards[nextIndex]
    }

    func canMoveForward(numberOfPages: Int, from cardName: String) -> Bool {
        guard let index = viewModel.availableCards
            .firstIndex(where: { $0.viewModel.name == cardName }),
              getNextOnboardingCard(
                currentIndex: index,
                numberOfCardsToMove: numberOfPages,
                goForward: true
              ) != nil
        else { return false}

        return true
    }

    func moveForward(numberOfPages: Int, from cardName: String) {
        guard let index = viewModel.availableCards
            .firstIndex(where: { $0.viewModel.name == cardName }),
              let nextViewController = getNextOnboardingCard(
                currentIndex: index,
                numberOfCardsToMove: numberOfPages,
                goForward: true
              )
        else { return }

        pageControl.currentPage = index + numberOfPages
        pageController.setViewControllers(
            [nextViewController],
            direction: .forward,
            animated: false)
    }

    // Due to restrictions with PageViewController we need to get the index of the current view controller
    // to calculate the next view controller
    func getCardIndex(viewController: OnboardingCardViewController) -> Int? {
        let cardName = viewController.viewModel.name

        guard let index = viewModel.availableCards
            .firstIndex(where: { $0.viewModel.name == cardName })
        else { return nil }

        return index
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public class OnboardingFlowViewModel<ViewModel: OnboardingCardInfoModelProtocol>: ObservableObject {
    @Published public var pageCount = 0
    public let onboardingCards: [ViewModel]
    public let onActionTap: (ViewModel.OnboardingActionType, String, @escaping (Result<TabAction, Error>) -> Void) -> Void

    public enum TabAction {
        case advance(numberOfPages: Int)
        case none
    }

    public let onComplete: (String) -> Void
    public private(set) var multipleChoiceSelections: [String: ViewModel.OnboardingMultipleChoiceActionType] = [:]

    public init(
        onboardingCards: [ViewModel],
        onActionTap: @escaping (
            ViewModel.OnboardingActionType,
            String,
            @escaping (Result<TabAction, Error>) -> Void
        ) -> Void,
        onComplete: @escaping (String) -> Void
    ) {
        self.onboardingCards = onboardingCards
        self.onActionTap = onActionTap
        self.onComplete = onComplete
    }

    public func handleBottomButtonAction(
        action: ViewModel.OnboardingActionType,
        cardName: String
    ) {
        onActionTap(action, cardName) { [weak self] result in
            switch result {
            case .success(let tabAction):
                switch tabAction {
                case .advance(let numberOfPages):
                    self?.advanceFromCard(cardName, by: numberOfPages)
                case .none:
                    return
                }
            case .failure:
                return
            }
        }
    }

    private func advanceFromCard(_ cardName: String, by numberOfPages: Int) {
        guard let index = onboardingCards.firstIndex(where: { $0.name == cardName }) else { return }
        let nextIndex = index + numberOfPages
        if nextIndex < onboardingCards.count {
            withAnimation {
                pageCount = nextIndex
            }
        } else {
            onComplete(cardName)
        }
    }

    public func handleMultipleChoiceAction(action: ViewModel.OnboardingMultipleChoiceActionType, cardName: String) {
        multipleChoiceSelections[cardName] = action
    }
}

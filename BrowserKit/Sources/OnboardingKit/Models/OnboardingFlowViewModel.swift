// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public enum OnboardingFlowOutcome: String {
    /// User advanced through every card to the natural end of the flow.
    case completed
    /// User tapped the skip button before reaching the last card.
    case skipped
}

@MainActor
public final class OnboardingFlowViewModel<ViewModel: OnboardingCardInfoModelProtocol>: ObservableObject {
    @Published public var pageCount = 0
    public let onboardingCards: [ViewModel]
    public let skipText: String
    public let variant: OnboardingVariant
    public let onActionTap: @MainActor (
        ViewModel.OnboardingActionType,
        String,
        @MainActor @escaping (Result<TabAction, Error>) -> Void
    ) -> Void
    public let onMultipleChoiceActionTap: @MainActor (
        ViewModel.OnboardingMultipleChoiceActionType,
        String
    ) -> Void

    public enum TabAction {
        case advance(numberOfPages: Int)
        case none
    }

    public let onComplete: @MainActor (String, OnboardingFlowOutcome) -> Void
    public private(set) var multipleChoiceSelections: [String: ViewModel.OnboardingMultipleChoiceActionType] = [:]

    public var onCardView: (@MainActor (String) -> Void)?
    public var onButtonTap: (@MainActor (String, ViewModel.OnboardingActionType, Bool) -> Void)?
    public var onMultipleChoiceTap: (@MainActor (String, ViewModel.OnboardingMultipleChoiceActionType) -> Void)?

    public init(
        onboardingCards: [ViewModel],
        skipText: String,
        variant: OnboardingVariant = .modern,
        onActionTap: @MainActor @escaping (
            ViewModel.OnboardingActionType,
            String,
            @MainActor @escaping (Result<TabAction, Error>) -> Void) -> Void,
        onMultipleChoiceActionTap: @MainActor @escaping (
            ViewModel.OnboardingMultipleChoiceActionType,
            String
        ) -> Void,
        onComplete: @MainActor @escaping (String, OnboardingFlowOutcome) -> Void
    ) {
        self.onboardingCards = onboardingCards
        self.skipText = skipText
        self.variant = variant
        self.onActionTap = onActionTap
        self.onMultipleChoiceActionTap = onMultipleChoiceActionTap
        self.onComplete = onComplete
    }

    public func handleBottomButtonAction(
        action: ViewModel.OnboardingActionType,
        cardName: String
    ) {
        let card = onboardingCards.first(where: { $0.name == cardName })
        let isPrimaryButton: Bool
        if let card = card {
            isPrimaryButton = card.buttons.primary.action.rawValue == action.rawValue
        } else {
            isPrimaryButton = false
        }
        onButtonTap?(cardName, action, isPrimaryButton)

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
            onComplete(cardName, .completed)
        }
    }

    public func handleMultipleChoiceAction(action: ViewModel.OnboardingMultipleChoiceActionType, cardName: String) {
        multipleChoiceSelections[cardName] = action
        onMultipleChoiceTap?(cardName, action)
        onMultipleChoiceActionTap(action, cardName)
    }

    public func skipOnboarding() {
        guard !onboardingCards.isEmpty else {
            return
        }

        let currentIndex = min(max(pageCount, 0), onboardingCards.count - 1)
        let currentCardName = onboardingCards[currentIndex].name
        onComplete(currentCardName, .skipped)
    }

    func scrollToNextPage() {
        guard !onboardingCards.isEmpty else { return }
        let maxIndex = onboardingCards.count - 1
        let next = min(pageCount + 1, maxIndex)
        guard next != pageCount else { return }
        pageCount = next
    }

    func scrollToPreviousPage() {
        guard !onboardingCards.isEmpty else { return }
        let previous = max(pageCount - 1, 0)
        guard previous != pageCount else { return }
        pageCount = previous
    }

    func handlePageChange() {
        guard pageCount >= 0 && pageCount < onboardingCards.count else { return }
        onCardView?(onboardingCards[pageCount].name)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

@MainActor
public final class OnboardingFlowViewModel<ViewModel: OnboardingCardInfoModelProtocol>: ObservableObject {
    @Published public var pageCount = 0
    public let onboardingCards: [ViewModel]
    public let skipText: String
    public let onActionTap: @MainActor (
        ViewModel.OnboardingActionType,
        String,
        @escaping (Result<TabAction, Error>) -> Void
    ) -> Void
    public let onMultipleChoiceActionTap: (
        ViewModel.OnboardingMultipleChoiceActionType,
        String
    ) -> Void

    public enum TabAction {
        case advance(numberOfPages: Int)
        case none
    }

    public let onComplete: (String) -> Void
    public private(set) var multipleChoiceSelections: [String: ViewModel.OnboardingMultipleChoiceActionType] = [:]
    
    // MARK: - Telemetry Callbacks
    /// Called when a card is viewed. Parameters: (cardName: String)
    public var onCardView: ((String) -> Void)?
    
    /// Called when a button is tapped. Parameters: (cardName: String, action: OnboardingActionType, isPrimary: Bool)
    public var onButtonTap: ((String, ViewModel.OnboardingActionType, Bool) -> Void)?
    
    /// Called when a multiple choice button is tapped. Parameters: (cardName: String, action: OnboardingMultipleChoiceActionType)
    public var onMultipleChoiceTap: ((String, ViewModel.OnboardingMultipleChoiceActionType) -> Void)?
    
    /// Called when onboarding is dismissed. Parameters: (cardName: String)
    public var onDismiss: ((String) -> Void)?

    public init(
        onboardingCards: [ViewModel],
        skipText: String,
        onActionTap: @MainActor @escaping (
            ViewModel.OnboardingActionType,
            String,
            @escaping (Result<TabAction, Error>) -> Void) -> Void,
        onMultipleChoiceActionTap: @escaping (
            ViewModel.OnboardingMultipleChoiceActionType,
            String
        ) -> Void,
        onComplete: @escaping (String) -> Void
    ) {
        self.onboardingCards = onboardingCards
        self.skipText = skipText
        self.onActionTap = onActionTap
        self.onMultipleChoiceActionTap = onMultipleChoiceActionTap
        self.onComplete = onComplete
    }

    public func handleBottomButtonAction(
        action: ViewModel.OnboardingActionType,
        cardName: String
    ) {
        // Determine if this is a primary or secondary button based on the card's button configuration
        let isPrimary: Bool
        if let card = onboardingCards.first(where: { $0.name == cardName }) {
            isPrimary = card.buttons.primary.action == action
        } else {
            // Default to primary if card not found
            isPrimary = true
        }
        
        // Send telemetry for button tap
        onButtonTap?(cardName, action, isPrimary)
        
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
            // Send telemetry for dismissal when completing onboarding
            onDismiss?(cardName)
            onComplete(cardName)
        }
    }

    public func handleMultipleChoiceAction(action: ViewModel.OnboardingMultipleChoiceActionType, cardName: String) {
        multipleChoiceSelections[cardName] = action
        // Send telemetry for multiple choice button tap
        onMultipleChoiceTap?(cardName, action)
        onMultipleChoiceActionTap(action, cardName)
    }

    public func skipOnboarding() {
        guard !onboardingCards.isEmpty else {
            return
        }

        let currentIndex = min(max(pageCount, 0), onboardingCards.count - 1)
        let currentCardName = onboardingCards[currentIndex].name
        // Send telemetry for dismissal
        onDismiss?(currentCardName)
        onComplete(currentCardName)
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
    
    /// Call this when pageCount changes to send card view telemetry
    func handlePageChange() {
        guard pageCount >= 0 && pageCount < onboardingCards.count else { return }
        let currentCardName = onboardingCards[pageCount].name
        onCardView?(currentCardName)
    }
}

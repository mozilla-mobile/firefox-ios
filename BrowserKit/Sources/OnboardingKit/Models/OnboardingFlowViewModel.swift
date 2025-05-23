// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public class OnboardingFlowViewModel<VM: OnboardingCardInfoModelProtocol>: ObservableObject {
    @Published public var pageCount = 0
    public let onboardingCards: [VM]
    public let onComplete: () -> Void
    public private(set) var multipleChoiceSelections: [String: VM.OnboardingMultipleChoiceActionType] = [:]

    public init(onboardingCards: [VM], onComplete: @escaping () -> Void) {
        self.onboardingCards = onboardingCards
        self.onComplete = onComplete
    }

    public func handleBottomButtonAction(
        action: VM.OnboardingActionType,
        cardName: String,
        isPrimary: Bool
    ) {
        guard let index = onboardingCards.firstIndex(where: { $0.name == cardName }) else { return }

        let nextIndex = index + 1
        if nextIndex < onboardingCards.count {
            withAnimation {
                pageCount = nextIndex
            }
        } else {
            onComplete()
        }
    }

    public func handleMultipleChoiceAction(action: VM.OnboardingMultipleChoiceActionType, cardName: String) {
        multipleChoiceSelections[cardName] = action
    }
}

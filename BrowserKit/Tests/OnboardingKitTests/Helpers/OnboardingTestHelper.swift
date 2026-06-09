// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import OnboardingKit

/// Helper class to track callback invocations and state during onboarding tests
@MainActor
final class OnboardingTestHelper {
    // MARK: - Properties
    private(set) var onActionTapCallCount = 0
    private(set) var onMultipleChoiceActionTapCallCount = 0
    private(set) var onCompleteCallCount = 0
    private(set) var lastCompletedCardName: String?
    private(set) var lastCompletionOutcome: OnboardingFlowOutcome?
    private(set) var lastActionTapped: MockOnboardingActionType?
    private(set) var lastMultipleChoiceAction: MockOnboardingMultipleChoiceActionType?

    // MARK: - Methods

    /// Resets all counters and tracked values
    func reset() {
        onActionTapCallCount = 0
        onMultipleChoiceActionTapCallCount = 0
        onCompleteCallCount = 0
        lastCompletedCardName = nil
        lastCompletionOutcome = nil
        lastActionTapped = nil
        lastMultipleChoiceAction = nil
    }

    // MARK: - Callback Handlers

    /// Handler for action tap callbacks
    func handleActionTap(
        action: MockOnboardingActionType,
        cardName: String,
        completion: @escaping (Result<OnboardingFlowViewModel<MockOnboardingCardInfoModel>.TabAction, Error>) -> Void
    ) {
        onActionTapCallCount += 1
        lastActionTapped = action
        completion(.success(.advance(numberOfPages: 1)))
    }

    /// Handler for multiple choice action callbacks
    func handleMultipleChoiceAction(action: MockOnboardingMultipleChoiceActionType, cardName: String) {
        onMultipleChoiceActionTapCallCount += 1
        lastMultipleChoiceAction = action
    }

    /// Handler for completion callbacks
    func handleCompletion(cardName: String, outcome: OnboardingFlowOutcome) {
        onCompleteCallCount += 1
        lastCompletedCardName = cardName
        lastCompletionOutcome = outcome
    }
}

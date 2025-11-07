// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import OnboardingKit

@MainActor
final class OnboardingFlowViewModelTests: XCTestCase {
    // MARK: - Properties
    private var testHelper: OnboardingTestHelper!

    // MARK: - Setup & Teardown
    override func setUp() async throws {
        try await super.setUp()
        testHelper = OnboardingTestHelper()
    }

    override func tearDown() async throws {
        testHelper = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods
    private func createViewModel(
        cards: [MockOnboardingCardInfoModel]? = nil
    ) -> OnboardingFlowViewModel<MockOnboardingCardInfoModel> {
        let defaultCards = cards ?? [
            MockOnboardingCardInfoModel.create(name: "card1", order: 0),
            MockOnboardingCardInfoModel.create(name: "card2", order: 1),
            MockOnboardingCardInfoModel.create(name: "card3", order: 2)
        ]

        return OnboardingFlowViewModel<MockOnboardingCardInfoModel>(
            onboardingCards: defaultCards,
            skipText: "Skip",
            onActionTap: testHelper.handleActionTap,
            onMultipleChoiceActionTap: testHelper.handleMultipleChoiceAction,
            onComplete: testHelper.handleCompletion
        )
    }

    // MARK: - Tests for skipOnboarding()

    func testSkipOnboarding_withDefaultPageCount_callsOnCompleteWithFirstCard() {
        // Given
        let viewModel = createViewModel()
        XCTAssertEqual(viewModel.pageCount, 0)

        // When
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onCompleteCallCount, 1)
        XCTAssertEqual(testHelper.lastCompletedCardName, "card1")
    }

    func testSkipOnboarding_withMiddlePageCount_callsOnCompleteWithCorrectCard() {
        // Given
        let viewModel = createViewModel()
        viewModel.pageCount = 1

        // When
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onCompleteCallCount, 1)
        XCTAssertEqual(testHelper.lastCompletedCardName, "card2")
    }

    func testSkipOnboarding_withLastPageCount_callsOnCompleteWithLastCard() {
        // Given
        let viewModel = createViewModel()
        viewModel.pageCount = 2

        // When
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onCompleteCallCount, 1)
        XCTAssertEqual(testHelper.lastCompletedCardName, "card3")
    }

    func testSkipOnboarding_withPageCountExceedingCardsCount_callsOnCompleteWithLastCard() {
        // Given
        let viewModel = createViewModel()
        viewModel.pageCount = 10 // Exceeds the number of cards (3)

        // When
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onCompleteCallCount, 1)
        XCTAssertEqual(testHelper.lastCompletedCardName, "card3") // Should clamp to last card
    }

    func testSkipOnboarding_withNegativePageCount_callsOnCompleteWithFirstCard() {
        // Given
        let viewModel = createViewModel()
        viewModel.pageCount = -5

        // When
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onCompleteCallCount, 1)
        XCTAssertEqual(testHelper.lastCompletedCardName, "card1") // Should clamp to first card
    }

    func testSkipOnboarding_withSingleCard_callsOnCompleteWithThatCard() {
        // Given
        let singleCard = [MockOnboardingCardInfoModel.create(name: "onlyCard", order: 0)]
        let viewModel = createViewModel(cards: singleCard)

        // When
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onCompleteCallCount, 1)
        XCTAssertEqual(testHelper.lastCompletedCardName, "onlyCard")
    }

    func testSkipOnboarding_calledMultipleTimes_callsOnCompleteMultipleTimes() {
        // Given
        let viewModel = createViewModel()

        // When
        viewModel.skipOnboarding()
        viewModel.skipOnboarding()
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onCompleteCallCount, 3)
        XCTAssertEqual(testHelper.lastCompletedCardName, "card1") // All calls should use same pageCount
    }

    func testSkipOnboarding_withDifferentCardNames_callsOnCompleteWithCorrectNames() {
        // Given
        let customCards = [
            MockOnboardingCardInfoModel.create(name: "welcome", order: 0),
            MockOnboardingCardInfoModel.create(name: "feature1", order: 1),
            MockOnboardingCardInfoModel.create(name: "feature2", order: 2),
            MockOnboardingCardInfoModel.create(name: "completion", order: 3)
        ]
        let viewModel = createViewModel(cards: customCards)

        // Test different page counts
        viewModel.pageCount = 0
        viewModel.skipOnboarding()
        XCTAssertEqual(testHelper.lastCompletedCardName, "welcome")

        testHelper.reset()
        viewModel.pageCount = 2
        viewModel.skipOnboarding()
        XCTAssertEqual(testHelper.lastCompletedCardName, "feature2")

        testHelper.reset()
        viewModel.pageCount = 3
        viewModel.skipOnboarding()
        XCTAssertEqual(testHelper.lastCompletedCardName, "completion")
    }

    func testSkipOnboarding_doesNotTriggerOtherCallbacks() {
        // Given
        let viewModel = createViewModel()

        // When
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onActionTapCallCount, 0)
        XCTAssertEqual(testHelper.onMultipleChoiceActionTapCallCount, 0)
        XCTAssertEqual(testHelper.onCompleteCallCount, 1)
        XCTAssertNil(testHelper.lastActionTapped)
        XCTAssertNil(testHelper.lastMultipleChoiceAction)
    }

    func testSkipOnboarding_withEmptyCards_handlesGracefully() {
        // Given
        let emptyCards: [MockOnboardingCardInfoModel] = []
        let viewModel = createViewModel(cards: emptyCards)

        // When
        viewModel.skipOnboarding()

        // Then
        XCTAssertEqual(testHelper.onCompleteCallCount, 0)
        XCTAssertNil(testHelper.lastCompletedCardName) // Should be nil string for empty cards
    }

    func testSkipOnboarding_boundaryConditions() {
        // Given
        let viewModel = createViewModel()

        // Test edge case where pageCount equals exactly the array count
        viewModel.pageCount = 3 // Equal to array count
        viewModel.skipOnboarding()
        XCTAssertEqual(testHelper.lastCompletedCardName, "card3")

        testHelper.reset()

        // Test zero pageCount with zero index
        viewModel.pageCount = 0
        viewModel.skipOnboarding()
        XCTAssertEqual(testHelper.lastCompletedCardName, "card1")
    }
}

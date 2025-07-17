// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import OnboardingKit

class OnboardingFlowViewModelTests: XCTestCase {
    var viewModel: OnboardingFlowViewModel<MockOnboardingCardInfoModel>!
    var mockCards: [MockOnboardingCardInfoModel]!

    var completionCallbacks: [(String) -> Void] = []
    var actionCallbacks: [(
        MockOnboardingCardInfoModel.OnboardingActionType,
        String,
        @escaping (Result<OnboardingFlowViewModel<MockOnboardingCardInfoModel>.TabAction, Error>) -> Void
    ) -> Void] = []
    var multipleChoiceCallbacks: [(MockOnboardingCardInfoModel.OnboardingMultipleChoiceActionType, String) -> Void] = []

    override func setUp() {
        super.setUp()
        mockCards = [
            MockOnboardingCardInfoModel(name: "card1"),
            MockOnboardingCardInfoModel(name: "card2"),
            MockOnboardingCardInfoModel(name: "card3")
        ]

        completionCallbacks = []
        actionCallbacks = []
        multipleChoiceCallbacks = []

        createViewModel()
    }

    override func tearDown() {
        viewModel = nil
        mockCards = nil
        completionCallbacks = []
        actionCallbacks = []
        multipleChoiceCallbacks = []
        super.tearDown()
    }

    private func createViewModel() {
        viewModel = OnboardingFlowViewModel(
            onboardingCards: mockCards,
            onActionTap: { [weak self] action, cardName, completion in
                self?.actionCallbacks.forEach { $0(action, cardName, completion) }
            },
            onMultipleChoiceActionTap: { [weak self] action, cardName in
                self?.multipleChoiceCallbacks.forEach { $0(action, cardName) }
            },
            onComplete: { [weak self] cardName in
                self?.completionCallbacks.forEach { $0(cardName) }
            }
        )
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertEqual(viewModel.pageCount, 0)
        XCTAssertEqual(viewModel.onboardingCards.count, 3)
        XCTAssertEqual(viewModel.onboardingCards[0].name, "card1")
        XCTAssertEqual(viewModel.onboardingCards[1].name, "card2")
        XCTAssertEqual(viewModel.onboardingCards[2].name, "card3")
        XCTAssertTrue(viewModel.multipleChoiceSelections.isEmpty)
    }

    // MARK: - Bottom Button Action Tests

    func testHandleBottomButtonAction_AdvanceByOne() {
        let expectation = self.expectation(description: "Action callback called")

        actionCallbacks.append { action, cardName, completion in
            XCTAssertEqual(action, .next)
            XCTAssertEqual(cardName, "card1")
            completion(.success(.advance(numberOfPages: 1)))
            expectation.fulfill()
        }

        viewModel.handleBottomButtonAction(action: .next, cardName: "card1")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.pageCount, 1)
        }
    }

    func testHandleBottomButtonAction_AdvanceByMultiple() {
        let expectation = self.expectation(description: "Action callback called")

        actionCallbacks.append { action, cardName, completion in
            XCTAssertEqual(action, .skip)
            XCTAssertEqual(cardName, "card1")
            completion(.success(.advance(numberOfPages: 2)))
            expectation.fulfill()
        }

        viewModel.handleBottomButtonAction(action: .skip, cardName: "card1")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.pageCount, 2)
        }
    }

    func testHandleBottomButtonAction_NoAdvance() {
        let expectation = self.expectation(description: "Action callback called")

        actionCallbacks.append { _, _, completion in
            completion(.success(.none))
            expectation.fulfill()
        }

        viewModel.handleBottomButtonAction(action: .complete, cardName: "card1")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.pageCount, 0) // Should remain unchanged
        }
    }

    func testHandleBottomButtonAction_ErrorHandling() {
        let expectation = self.expectation(description: "Action callback called")

        actionCallbacks.append { _, _, completion in
            completion(.failure(NSError(domain: "test", code: 1, userInfo: nil)))
            expectation.fulfill()
        }

        viewModel.handleBottomButtonAction(action: .next, cardName: "card1")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.pageCount, 0) // Should remain unchanged
        }
    }

    func testHandleBottomButtonAction_CompletionWhenAdvancingBeyondCards() {
        let actionExpectation = self.expectation(description: "Action callback called")
        let completionExpectation = self.expectation(description: "Completion callback called")

        actionCallbacks.append { _, _, completion in
            completion(.success(.advance(numberOfPages: 5))) // Advance beyond available cards
            actionExpectation.fulfill()
        }

        completionCallbacks.append { cardName in
            XCTAssertEqual(cardName, "card1")
            completionExpectation.fulfill()
        }

        viewModel.handleBottomButtonAction(action: .next, cardName: "card1")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.pageCount, 0) // Should remain unchanged when completing
        }
    }

    func testHandleBottomButtonAction_InvalidCardName() {
        let expectation = self.expectation(description: "Action callback called")

        actionCallbacks.append { _, _, completion in
            completion(.success(.advance(numberOfPages: 1)))
            expectation.fulfill()
        }

        viewModel.handleBottomButtonAction(action: .next, cardName: "nonexistent")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.pageCount, 0) // Should remain unchanged
        }
    }

    // MARK: - Multiple Choice Action Tests

    func testHandleMultipleChoiceAction() {
        let expectation = self.expectation(description: "Multiple choice callback called")

        multipleChoiceCallbacks.append { action, cardName in
            XCTAssertEqual(action, .optionA)
            XCTAssertEqual(cardName, "card1")
            expectation.fulfill()
        }

        viewModel.handleMultipleChoiceAction(action: .optionA, cardName: "card1")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.multipleChoiceSelections["card1"], .optionA)
        }
    }

    func testHandleMultipleChoiceAction_MultipleSelections() {
        let expectation1 = self.expectation(description: "First multiple choice callback")
        let expectation2 = self.expectation(description: "Second multiple choice callback")

        multipleChoiceCallbacks.append { _, cardName in
            if cardName == "card1" {
                expectation1.fulfill()
            } else if cardName == "card2" {
                expectation2.fulfill()
            }
        }

        viewModel.handleMultipleChoiceAction(action: .optionA, cardName: "card1")
        viewModel.handleMultipleChoiceAction(action: .optionB, cardName: "card2")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.multipleChoiceSelections["card1"], .optionA)
            XCTAssertEqual(self.viewModel.multipleChoiceSelections["card2"], .optionB)
        }
    }

    func testHandleMultipleChoiceAction_OverwriteSelection() {
        let expectation1 = self.expectation(description: "First selection")
        let expectation2 = self.expectation(description: "Second selection")

        multipleChoiceCallbacks.append { action, _ in
            if action == .optionA {
                expectation1.fulfill()
            } else if action == .optionB {
                expectation2.fulfill()
            }
        }

        viewModel.handleMultipleChoiceAction(action: .optionA, cardName: "card1")
        viewModel.handleMultipleChoiceAction(action: .optionB, cardName: "card1")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(self.viewModel.multipleChoiceSelections["card1"], .optionB)
            XCTAssertEqual(self.viewModel.multipleChoiceSelections.count, 1)
        }
    }

    // MARK: - PageCount Change Tests

    func testPageCountChanges() {
        let expectation = self.expectation(description: "Action callback called")

        actionCallbacks.append { _, _, completion in
            completion(.success(.advance(numberOfPages: 1)))
            expectation.fulfill()
        }

        let initialPageCount = viewModel.pageCount
        viewModel.handleBottomButtonAction(action: .next, cardName: "card1")

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(initialPageCount, 0)
            XCTAssertEqual(self.viewModel.pageCount, 1)
        }
    }

    // MARK: - Edge Cases

    func testEmptyOnboardingCards() {
        let emptyViewModel = OnboardingFlowViewModel<MockOnboardingCardInfoModel>(
            onboardingCards: [],
            onActionTap: { _, _, completion in
                completion(.success(.advance(numberOfPages: 1)))
            },
            onMultipleChoiceActionTap: { _, _ in },
            onComplete: { _ in }
        )

        XCTAssertEqual(emptyViewModel.onboardingCards.count, 0)
        XCTAssertEqual(emptyViewModel.pageCount, 0)
    }

    func testAdvanceFromLastCard() {
        let expectation = self.expectation(description: "Completion called")

        // Start from the last card
        viewModel = OnboardingFlowViewModel(
            onboardingCards: mockCards,
            onActionTap: { _, _, completion in
                completion(.success(.advance(numberOfPages: 1)))
            },
            onMultipleChoiceActionTap: { _, _ in },
            onComplete: { cardName in
                XCTAssertEqual(cardName, "card3")
                expectation.fulfill()
            }
        )

        // Manually set to last card
        viewModel.pageCount = 2

        viewModel.handleBottomButtonAction(action: .next, cardName: "card3")

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Memory Management Tests

    func testWeakSelfInClosures() {
        var localViewModel: OnboardingFlowViewModel<MockOnboardingCardInfoModel>? = OnboardingFlowViewModel(
            onboardingCards: mockCards,
            onActionTap: { _, _, completion in
                completion(.success(.advance(numberOfPages: 1)))
            },
            onMultipleChoiceActionTap: { _, _ in },
            onComplete: { _ in }
        )

        weak var weakViewModel = localViewModel

        localViewModel?.handleBottomButtonAction(action: .next, cardName: "card1")

        localViewModel = nil

        // Verify that the view model is deallocated
        XCTAssertNil(weakViewModel)
    }
}

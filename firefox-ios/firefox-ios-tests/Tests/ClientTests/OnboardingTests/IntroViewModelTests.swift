// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

class IntroViewModelTests: XCTestCase {
    var nimbusUtility: NimbusOnboardingTestingConfigUtility!
    typealias cards = NimbusOnboardingTestingConfigUtility.CardOrder
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        nimbusUtility = NimbusOnboardingTestingConfigUtility()
    }

    override func tearDown() {
        nimbusUtility = nil
        super.tearDown()
    }

    func testModel_whenInitialized_hasNoViewControllers() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let subject = createSubject()
        let expectedNumberOfViewControllers = 0

        XCTAssertEqual(subject.availableCards.count, expectedNumberOfViewControllers)
    }

    func testModel_whenInitializedWithAllCards_onlyReturnsOnboardingCards() {
        nimbusUtility.setupNimbus(withOrder: cards.allCards)
        let subject = createSubject()
        let expectedNumberOfViewControllers = 3

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        XCTAssertEqual(subject.availableCards.count, expectedNumberOfViewControllers)
        XCTAssertEqual(subject.availableCards[0].viewModel.name, cards.welcome.rawValue)
        XCTAssertEqual(subject.availableCards[1].viewModel.name, cards.notifications.rawValue)
        XCTAssertEqual(subject.availableCards[2].viewModel.name, cards.sync.rawValue)
    }

    func testModel_hasThreeAvailableCards_inExpectedOrder() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let subject = createSubject()
        let expectedNumberOfViewControllers = 3

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        XCTAssertEqual(subject.availableCards.count, expectedNumberOfViewControllers)
        XCTAssertEqual(subject.availableCards[0].viewModel.name, cards.welcome.rawValue)
        XCTAssertEqual(subject.availableCards[1].viewModel.name, cards.notifications.rawValue)
        XCTAssertEqual(subject.availableCards[2].viewModel.name, cards.sync.rawValue)
    }

    func testModel_hasTwoAvailableCards_inExpectedOrder() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeSync)
        let subject = createSubject()
        let expectedNumberOfViewControllers = 2

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        XCTAssertEqual(subject.availableCards.count, expectedNumberOfViewControllers)
        XCTAssertEqual(subject.availableCards[0].viewModel.name, cards.welcome.rawValue)
        XCTAssertEqual(subject.availableCards[1].viewModel.name, cards.sync.rawValue)
    }

    // MARK: - Test index moving forward
    func testIndexAfterFirstCard() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let subject = createSubject()
        let expectedIndex = 1

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        let resultIndex = subject.getNextIndexFrom(
            currentIndex: 0,
            numberOfCardsToMove: 1,
            goForward: true
        )
        XCTAssertEqual(resultIndex, expectedIndex)
    }

    func testIndexAfterSecondCard() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let subject = createSubject()
        let expectedIndex = 2

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        let resultIndex = subject.getNextIndexFrom(
            currentIndex: 1,
            numberOfCardsToMove: 1,
            goForward: true
        )
        XCTAssertEqual(resultIndex, expectedIndex)
    }

    func testNextIndexAfterLastCard() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let subject = createSubject()

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        let resultIndex = subject.getNextIndexFrom(
            currentIndex: 2,
            numberOfCardsToMove: 1,
            goForward: true
        )
        XCTAssertNil(resultIndex)
    }

    // MARK: - Test index moving backwards
    func testIndexBeforeLastCard() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let subject = createSubject()
        let expectedIndex = 1

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        let resultIndex = subject.getNextIndexFrom(
            currentIndex: 2,
            numberOfCardsToMove: 1,
            goForward: false
        )
        XCTAssertEqual(resultIndex, expectedIndex)
    }

    func testIndexBeforeSecondCard() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let subject = createSubject()
        let expectedIndex = 0

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        let resultIndex = subject.getNextIndexFrom(
            currentIndex: 1,
            numberOfCardsToMove: 1,
            goForward: false
        )
        XCTAssertEqual(resultIndex, expectedIndex)
    }

    func testNextIndexBeforeFirstCard() {
        nimbusUtility.setupNimbus(withOrder: cards.welcomeNotificationSync)
        let subject = createSubject()

        subject.setupViewControllerDelegates(with: MockOnboardinCardDelegateController(), for: windowUUID)

        let resultIndex = subject.getNextIndexFrom(
            currentIndex: 0,
            numberOfCardsToMove: 1,
            goForward: false
        )
        XCTAssertNil(resultIndex)
    }

    // MARK: - Private Helpers
    func createSubject(
        file: StaticString = #file,
        line: UInt = #line
    ) -> IntroViewModel {
        let onboardingViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingViewModel)
        let subject = IntroViewModel(
            profile: MockProfile(databasePrefix: "introViewModelTests_"),
            model: onboardingViewModel,
            telemetryUtility: telemetryUtility)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class OnboardingViewControllerProtocolTests: XCTestCase {
    var nimbusUtility: NimbusOnboardingTestingConfigUtility!
    typealias cards = NimbusOnboardingTestingConfigUtility.CardOrder

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        nimbusUtility = NimbusOnboardingTestingConfigUtility()
        nimbusUtility.setupNimbus(withOrder: cards.allCards)
    }

    override func tearDown() {
        nimbusUtility = nil
        super.tearDown()
    }

    // MARK: - Test `getNextOnboardingCard` forward
    func testProtocol_hasCorrectFirstViewController() {
        let subject = createSubject()

        guard let result = subject.pageController.viewControllers?.first as? OnboardingBasicCardViewController else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        XCTAssertEqual(result.viewModel.name, cards.welcome.rawValue)
    }

    func testProtocol_getsCorrectViewController_notifications() {
        let subject = createSubject()

        guard let result = subject.getNextOnboardingCard(
            currentIndex: 0,
            numberOfCardsToMove: 1,
            goForward: true
        ) else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        XCTAssertEqual(result.viewModel.name, cards.notifications.rawValue)
    }

    func testProtocol_getsCorrectViewController_sync() {
        let subject = createSubject()

        guard let result = subject.getNextOnboardingCard(
            currentIndex: 1,
            numberOfCardsToMove: 1,
            goForward: true
        ) else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        XCTAssertEqual(result.viewModel.name, cards.sync.rawValue)
    }

    func testProtocol_getsNoViewController_afterLastCard() {
        let subject = createSubject()

        let result = subject.getNextOnboardingCard(
            currentIndex: 2,
            numberOfCardsToMove: 1,
            goForward: true
        )

        XCTAssertNil(result)
    }

    // MARK: - Test `getNextOnboardingCard` backwards
    func testProtocol_getsNoViewController_beforeFirstCard() {
        let subject = createSubject()

        let result = subject.getNextOnboardingCard(
            currentIndex: 2,
            numberOfCardsToMove: 1,
            goForward: true
        )

        XCTAssertNil(result)
    }

    func testProtocol_getsCorrectViewController_fromSecondCard_isWelcome() {
        let subject = createSubject()

        guard let result = subject.getNextOnboardingCard(
            currentIndex: 1,
            numberOfCardsToMove: 1,
            goForward: false
        ) else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        XCTAssertEqual(result.viewModel.name, cards.welcome.rawValue)
    }

    func testProtocol_getsCorrectViewController_fromThirdCard_isNotifications() {
        let subject = createSubject()

        guard let result = subject.getNextOnboardingCard(
            currentIndex: 2,
            numberOfCardsToMove: 1,
            goForward: false
        ) else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        XCTAssertEqual(result.viewModel.name, cards.notifications.rawValue)
    }

    // MARK: - Test `moveToNextPage`
    func testProtocol_initialIndex_isZero() {
        let subject = createSubject()

        guard let result = subject.pageController.viewControllers?.first as? OnboardingBasicCardViewController else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        XCTAssertEqual(subject.pageControl.currentPage, 0)
        XCTAssertEqual(result.viewModel.name, cards.welcome.rawValue)
    }

    func testProtocol_moveToNextPage_FromFirstCard() {
        let subject = createSubject()

        subject.moveForward(numberOfPages: 1, from: cards.welcome.rawValue)
        guard let result = subject.pageController.viewControllers?.first as? OnboardingBasicCardViewController else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        XCTAssertEqual(subject.pageControl.currentPage, 1)
        XCTAssertEqual(result.viewModel.name, cards.notifications.rawValue)
    }

    func testProtocol_moveToNextPage_FromSecondCard() {
        let subject = createSubject()

        subject.moveForward(numberOfPages: 1, from: cards.notifications.rawValue)
        guard let result = subject.pageController.viewControllers?.first as? OnboardingBasicCardViewController else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        XCTAssertEqual(subject.pageControl.currentPage, 2)
        XCTAssertEqual(result.viewModel.name, cards.sync.rawValue)
    }

    // MARK: - Test `getCardIndex`
    func testProtocol_getsCorrectCardIndexes() {
        let subject = createSubject()
        let welcomeCard = subject.viewModel.availableCards[0]
        let notificationCard = subject.viewModel.availableCards[1]
        let syncCard = subject.viewModel.availableCards[2]

        guard let welcomeResult = subject.getCardIndex(viewController: welcomeCard),
              let notificationResult = subject.getCardIndex(viewController: notificationCard),
              let syncResult = subject.getCardIndex(viewController: syncCard)
        else {
            XCTFail("expected an index, but got nothing")
            return
        }

        XCTAssertEqual(welcomeResult, 0)
        XCTAssertEqual(notificationResult, 1)
        XCTAssertEqual(syncResult, 2)
    }

    // MARK: - Private Helpers
    func createSubject(
        file: StaticString = #file,
        line: UInt = #line
    ) -> IntroViewController {
        let onboardingViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingViewModel)
        let viewModel = IntroViewModel(profile: MockProfile(),
                                       model: onboardingViewModel,
                                       telemetryUtility: telemetryUtility)
        let subject = IntroViewController(viewModel: viewModel, windowUUID: .XCTestDefaultUUID)

        subject.viewDidLoad()
        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}

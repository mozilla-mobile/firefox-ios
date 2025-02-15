// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class IntroViewControllerTests: XCTestCase {
    var mockNotificationCenter: MockNotificationCenter!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockNotificationCenter = MockNotificationCenter()
    }

    override func tearDown() {
        mockNotificationCenter = nil
        super.tearDown()
    }

    // Temp. Disabled: https://mozilla-hub.atlassian.net/browse/FXIOS-7505
    func testBasicSetupReturnsExpectedItems() {
        let subject = createSubject()
        XCTAssertEqual(subject.viewModel.availableCards.count, 3)
        XCTAssertEqual(
            subject.viewModel.availableCards[0].viewModel.buttons.primary.action,
            .setDefaultBrowser
        )
        XCTAssertEqual(subject.viewModel.availableCards[0].viewModel.name, "Name 1")
        XCTAssertEqual(subject.viewModel.availableCards[1].viewModel.name, "Name 2")
        XCTAssertEqual(subject.viewModel.availableCards[2].viewModel.name, "Name 3")
    }

    func testSubjectRegistersForNotification() {
        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 0)
        let subject = createSubject()

        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 1)
        subject.registerForNotification()

        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 2)
    }

    func testViewMoving_MovesToNextCard_ifSetDefaultBrowserCard() {
        let subject = createSubject()

        XCTAssertEqual(subject.pageControl.currentPage, 0)
        subject.appDidEnterBackgroundNotification()

        XCTAssertEqual(subject.pageControl.currentPage, 1)
    }

    func testViewMoving_StaysOnCurrentScreen_ifNotASetDefaultBrowserCard() {
        let subject = createSubject(withCustomPrimaryActions: [.syncSignIn, .setDefaultBrowser, .requestNotifications])

        XCTAssertEqual(subject.pageControl.currentPage, 0)
        subject.appDidEnterBackgroundNotification()

        XCTAssertEqual(subject.pageControl.currentPage, 0)
    }

    func testViewMoving_MovesToNextCard_ifSetDefaultBrowserCardIfNotFirstPosition() {
        let subject = createSubject(withCustomPrimaryActions: [.syncSignIn, .setDefaultBrowser, .requestNotifications])

        XCTAssertEqual(subject.pageControl.currentPage, 0)
        subject.advance(
            numberOfPages: 1,
            from: subject.viewModel.availableCards[subject.pageControl.currentPage].viewModel.name,
            completionIfLastCard: nil)
        XCTAssertEqual(subject.pageControl.currentPage, 1)
        subject.appDidEnterBackgroundNotification()

        XCTAssertEqual(subject.pageControl.currentPage, 2)
    }

    func testViewMovesToNextScreenAfterNotification() {
        let subject = createSubject()
        XCTAssertEqual(subject.pageControl.currentPage, 0)

        // Pretending to tap the button that would register for the notification
        subject.registerForNotification()
        mockNotificationCenter.post(name: UIApplication.didEnterBackgroundNotification)

        XCTAssertEqual(mockNotificationCenter.postCallCount, 1)
        XCTAssertEqual(subject.pageControl.currentPage, 1)
    }

    // MARK: - Private Helpers
    func createSubject(
        withCustomPrimaryActions: [OnboardingActions] = [.setDefaultBrowser, .syncSignIn, .requestNotifications],
        file: StaticString = #file,
        line: UInt = #line
    ) -> IntroViewController {
        NimbusOnboardingTestingConfigUtility().setupNimbusWith(
            image: .notifications,
            onboardingType: .freshInstall,
            dismissable: true,
            shouldAddLink: false,
            withSecondaryButton: true,
            withPrimaryButtonAction: withCustomPrimaryActions
        )

        let onboardingViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingViewModel)
        let viewModel = IntroViewModel(profile: MockProfile(),
                                       model: onboardingViewModel,
                                       telemetryUtility: telemetryUtility)
        let subject = IntroViewController(viewModel: viewModel,
                                          windowUUID: .XCTestDefaultUUID,
                                          notificationCenter: mockNotificationCenter)

        trackForMemoryLeaks(subject, file: file, line: line)
        mockNotificationCenter.notifiableListener = subject

        return subject
    }
}

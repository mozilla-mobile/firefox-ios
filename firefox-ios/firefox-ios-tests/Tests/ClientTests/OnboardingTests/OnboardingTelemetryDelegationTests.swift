// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

class OnboardingTelemetryDelegationTests: XCTestCase {
    var nimbusUtility: NimbusOnboardingTestingConfigUtility!
    typealias cards = NimbusOnboardingTestingConfigUtility.CardOrder

    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().bootstrapDependencies()
        nimbusUtility = NimbusOnboardingTestingConfigUtility()
        nimbusUtility.setupNimbus(withOrder: cards.allCards)
    }

    override func tearDown() {
        nimbusUtility = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testOnboardingCard_viewDidAppear_viewSendsCardView() {
        let subject = createSubject()
        guard let firstVC = subject.pageController.viewControllers?.first as? OnboardingBasicCardViewController else {
            XCTFail("expected a view controller, but got nothing")
            return
        }
        firstVC.viewDidAppear(true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.cardView)
    }

    func testOnboardingCard_callsPrimaryButtonTap() {
        let subject = createSubject()
        guard let firstVC = subject.pageController.viewControllers?.first as? OnboardingBasicCardViewController else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        firstVC.primaryAction()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.primaryButtonTap)
    }

    func testOnboardingCard_callsSecondaryButtonTap() {
        let subject = createSubject()
        guard let firstVC = subject.pageController.viewControllers?.first as? OnboardingBasicCardViewController else {
            XCTFail("expected a view controller, but got nothing")
            return
        }
        subject.advance(
            numberOfPages: 1,
            from: firstVC.viewModel.name,
            completionIfLastCard: { })
        subject.pageChanged(from: firstVC.viewModel.name)
        guard let result = subject.pageController
            .viewControllers?[subject.pageControl.currentPage] as? OnboardingBasicCardViewController else {
            XCTFail("expected a view controller, but got nothing")
            return
        }

        result.secondaryAction()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.secondaryButtonTap)
    }

    func testOnboardingCard_callsCloseTap() {
        let subject = createSubject()

        subject.closeOnboarding()

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.closeTap)
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

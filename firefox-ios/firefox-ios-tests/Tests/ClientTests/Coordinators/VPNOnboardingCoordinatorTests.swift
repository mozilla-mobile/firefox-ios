// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import ComponentLibrary
import Shared
import TestKit

@testable import Client
@testable import ComponentLibrary

@available(iOS 27.2, *)
@MainActor
final class VPNOnboardingCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var prefs: MockProfilePrefs!
    private var featureFlagsProvider: MockNimbusFeatureFlags!
    private var telemetry: MockVPNClientTelemetry!
    private var parentCoordinator: MockParentCoordinator!
    private var delegate: MockVPNOnboardingCoordinatorDelegate!
    private var tabManager: MockTabManager!
    private var openedURLs: [URL] = []

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        router = MockRouter(navigationController: MockNavigationController())
        prefs = MockProfilePrefs()
        featureFlagsProvider = MockNimbusFeatureFlags()
        featureFlagsProvider.enabledFlags = [.vpnFeature, .vpnOnboardingSheet]
        telemetry = MockVPNClientTelemetry()
        parentCoordinator = MockParentCoordinator()
        delegate = MockVPNOnboardingCoordinatorDelegate()
        tabManager = MockTabManager()
        tabManager.selectedTab = makeTab()
        openedURLs = []
    }

    override func tearDown() async throws {
        router = nil
        prefs = nil
        featureFlagsProvider = nil
        telemetry = nil
        parentCoordinator = nil
        delegate = nil
        tabManager = nil
        openedURLs = []
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - shouldShow

    func test_shouldShow_whenSelectedTabIsWebsite_returnsTrue() {
        let subject = createSubject()

        XCTAssertTrue(subject.shouldShow())
    }

    func test_shouldShow_whenSelectedTabIsPrivateWebsite_returnsTrue() {
        tabManager.selectedTab = makeTab(isPrivate: true)
        let subject = createSubject()

        XCTAssertTrue(subject.shouldShow())
    }

    func test_shouldShow_whenNoSelectedTab_returnsFalse() {
        tabManager.selectedTab = nil
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenSelectedTabIsHomepage_returnsFalse() {
        tabManager.selectedTab = makeTab(isHomePage: true)
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenVPNFlagDisabled_returnsFalse() {
        featureFlagsProvider.enabledFlags = [.vpnOnboardingSheet]
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenOnboardingSheetFlagDisabled_returnsFalse() {
        featureFlagsProvider.enabledFlags = [.vpnFeature]
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    func test_shouldShow_whenSheetAlreadyShown_returnsFalse() {
        prefs.setBool(true, forKey: PrefsKeys.VPNSettings.onboardingSheetShown)
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShow())
    }

    // MARK: - start

    func test_start_presentsPageSheetWithASingleCustomDetent() throws {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        let sheet = try XCTUnwrap(router.presentedViewController as? OnboardingSheetViewController)
        XCTAssertEqual(sheet.modalPresentationStyle, .pageSheet)
        let detents = try XCTUnwrap(sheet.sheetPresentationController?.detents.map(\.identifier))
        XCTAssertEqual(detents.count, 1)
        XCTAssertFalse([.medium, .large].contains(detents.first))
    }

    func test_start_setsShownPref() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(prefs.boolForKey(PrefsKeys.VPNSettings.onboardingSheetShown), true)
        XCTAssertFalse(subject.shouldShow())
    }

    func test_start_recordsShown() {
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(telemetry.onboardingShownCount, 1)
    }

    func test_start_whenSheetIsSwipedDown_recordsCancelledAndNotifiesParent() {
        let subject = createSubject()
        subject.start()

        router.savedCompletion?()

        XCTAssertEqual(telemetry.onboardingCancelledCount, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // MARK: - Close

    func test_close_recordsCancelledAndNotifiesParent() throws {
        let subject = createSubject()
        subject.start()

        try presentedSheet().onDismiss()

        XCTAssertEqual(telemetry.onboardingCancelledCount, 1)
        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // MARK: - CTA

    func test_cta_recordsTapAndCallsDelegate() throws {
        let subject = createSubject()
        subject.start()

        try presentedSheet().onCTA()
        router.savedCompletion?()

        XCTAssertEqual(telemetry.onboardingCTATappedCount, 1)
        XCTAssertEqual(telemetry.onboardingCancelledCount, 0)
        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(delegate.didTapCTACalled, 1)
    }

    // MARK: - Learn more

    func test_learnMore_recordsTapAndOpensLearnMoreURL() throws {
        let learnMoreURL = try XCTUnwrap(VPNSettingsViewController.learnMoreURL)
        let subject = createSubject()
        subject.start()

        try presentedSheet().onLearnMore()

        XCTAssertEqual(telemetry.onboardingLearnMoreLinkTappedCount, 1)
        XCTAssertEqual(telemetry.onboardingCancelledCount, 0)
        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(openedURLs, [learnMoreURL])
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> VPNOnboardingCoordinator {
        let subject = VPNOnboardingCoordinator(
            router: router,
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            prefs: prefs,
            telemetry: telemetry,
            featureFlagsProvider: featureFlagsProvider,
            onOpenURL: { [weak self] url in
                self?.openedURLs.append(url)
            }
        )
        subject.parentCoordinator = parentCoordinator
        subject.delegate = delegate
        trackForMemoryLeaks(subject)
        return subject
    }

    private func presentedSheet() throws -> OnboardingSheetViewController {
        return try XCTUnwrap(router.presentedViewController as? OnboardingSheetViewController)
    }

    private func makeTab(isPrivate: Bool = false, isHomePage: Bool = false) -> Tab {
        return MockTab(
            profile: makeProfile(),
            isPrivate: isPrivate,
            windowUUID: .XCTestDefaultUUID,
            isHomePage: isHomePage
        )
    }
}

private final class MockVPNOnboardingCoordinatorDelegate: VPNOnboardingCoordinatorDelegate {
    var didTapCTACalled = 0

    func vpnOnboardingDidTapCTA(from coordinator: Coordinator) {
        didTapCTACalled += 1
    }
}

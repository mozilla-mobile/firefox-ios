// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
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
    private var tabManager: MockTabManager!
    private var horizontalSizeClass: UIUserInterfaceSizeClass = .compact

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        router = MockRouter(navigationController: MockNavigationController())
        prefs = MockProfilePrefs()
        featureFlagsProvider = MockNimbusFeatureFlags()
        featureFlagsProvider.enabledFlags = [.vpnFeature, .vpnOnboardingSheet]
        telemetry = MockVPNClientTelemetry()
        parentCoordinator = MockParentCoordinator()
        tabManager = MockTabManager()
        tabManager.selectedTab = makeTab()
    }

    override func tearDown() async throws {
        router = nil
        prefs = nil
        featureFlagsProvider = nil
        telemetry = nil
        parentCoordinator = nil
        tabManager = nil
        horizontalSizeClass = .compact
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

    func test_start_whenHorizontalSizeClassIsCompact_presentsFormSheetWithCustomAndLargeDetents() throws {
        horizontalSizeClass = .compact
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 1)
        let sheet = try presentedSheet()
        XCTAssertEqual(sheet.modalPresentationStyle, .formSheet)
        let detents = try XCTUnwrap(sheet.sheetPresentationController?.detents.map(\.identifier))
        XCTAssertEqual(detents.count, 2)
        XCTAssertEqual(detents.last, .large)
    }

    func test_start_whenHorizontalSizeClassIsRegular_keepsDefaultDetents() throws {
        horizontalSizeClass = .regular
        let subject = createSubject()

        subject.start()

        let sheet = try presentedSheet()
        let detents = try XCTUnwrap(sheet.sheetPresentationController?.detents.map(\.identifier))
        XCTAssertEqual(detents, [.large])
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

    // MARK: - Helpers

    private func createSubject() -> VPNOnboardingCoordinator {
        let subject = VPNOnboardingCoordinator(
            router: router,
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            prefs: prefs,
            telemetry: telemetry,
            featureFlagsProvider: featureFlagsProvider,
            traitCollectionProvider: { [horizontalSizeClass] in
                UITraitCollection(horizontalSizeClass: horizontalSizeClass)
            },
            onOpenURL: { _ in }
        )
        subject.parentCoordinator = parentCoordinator
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

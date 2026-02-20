// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared
@testable import Client

@MainActor
final class TermsOfUseCoordinatorTests: XCTestCase {
    private var profile: MockProfile!
    private var router: MockRouter!
    private var notificationCenter: MockNotificationCenter!
    private var coordinator: TermsOfUseCoordinator!
    private let windowUUID = WindowUUID.XCTestDefaultUUID

    private enum TimeConstants {
        static let oneHourInSeconds: TimeInterval = 60 * 60
        static let timeoutHours = 120
        static let hoursAfterTimeout = 2
    }

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        router = MockRouter(navigationController: MockNavigationController())
        notificationCenter = MockNotificationCenter()
        setupNimbusTouFeatureForTesting(isEnabled: true, maxRemindersCount: 5)

        coordinator = TermsOfUseCoordinator(
            windowUUID: windowUUID,
            router: router,
            themeManager: AppContainer.shared.resolve(),
            notificationCenter: notificationCenter,
            prefs: profile.prefs,
            experimentsTracking: ToUExperimentsTracking(prefs: profile.prefs)
        )
    }

    override func tearDown() async throws {
        coordinator = nil
        router = nil
        notificationCenter = nil
        profile = nil
        // Reset timeout override to ensure clean state
        UserDefaults.standard.removeObject(forKey: PrefsKeys.FasterTermsOfUseTimeoutOverride)
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testShouldShowTermsOfUse_ReturnsFalse_WhenAlreadyAccepted() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)

        let result = coordinator.shouldShowTermsOfUse(context: .appLaunch)

        XCTAssertFalse(result)
    }

    func testShouldShowTermsOfUse_ReturnsFalse_WhenTermsOfServiceAccepted() {
        // Test that legacy TermsOfServiceAccepted is migrated and recognized
        profile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)

        // Trigger migration explicitly (as it would happen in AppLaunchUtil)
        TermsOfUseMigration(prefs: profile.prefs).migrateTermsOfService()

        let result = coordinator.shouldShowTermsOfUse(context: .appLaunch)

        XCTAssertFalse(result)
        // Verify migration happened - TermsOfUseAccepted should be set
        XCTAssertTrue(profile.prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false)
    }

    func testShouldShowTermsOfUse_ReturnsFalse_WhenTimeoutPeriodNotElapsed() {
        setNormalTimeout()
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)

        let dismissedDate = Date().addingTimeInterval(-TimeConstants.oneHourInSeconds)
        profile.prefs.setTimestamp(dismissedDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseDismissedDate)

        let result = coordinator.shouldShowTermsOfUse(context: .appLaunch)

        XCTAssertFalse(result)
    }

    func testShouldShowTermsOfUse_ReturnsTrue_WhenTimeoutPeriodElapsed() {
        setNormalTimeout()
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)

        let hoursElapsed = TimeConstants.timeoutHours + TimeConstants.hoursAfterTimeout
        let dismissedDate = Date().addingTimeInterval(-TimeInterval(hoursElapsed) * TimeConstants.oneHourInSeconds)
        profile.prefs.setTimestamp(dismissedDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseDismissedDate)

        let result = coordinator.shouldShowTermsOfUse(context: .appLaunch)

        XCTAssertTrue(result)
    }

    func testShouldShowTermsOfUse_ReturnsFalse_WhenRemindersCountExceedsMax() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        profile.prefs.setInt(100, forKey: PrefsKeys.TermsOfUseRemindersCount)

        let result = coordinator.shouldShowTermsOfUse(context: .appLaunch)

        XCTAssertFalse(result)
    }

    func testShouldShowTermsOfUse_ReturnsTrue_WhenRemindersCountBelowMax_AndNoDismissalRecord() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
        profile.prefs.setInt(0, forKey: PrefsKeys.TermsOfUseRemindersCount)

        let result = coordinator.shouldShowTermsOfUse(context: .appLaunch)

        XCTAssertTrue(result)
    }

    func testStart_DoesNotPresent_WhenShouldShowReturnsFalse() {
        profile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)

        coordinator.start(context: .appLaunch)

        XCTAssertEqual(router.presentCalled, 0)
    }

    func testDismissTermsFlow_CallsRouterDismiss() {
        coordinator.dismissTermsFlow()

        XCTAssertEqual(router.dismissCalled, 1)
    }

    private func setupNimbusTouFeatureForTesting(
        isEnabled: Bool,
        maxRemindersCount: Int32 = 5,
        enableDragToDismiss: Bool = true,
        contentOption: TermsOfUsePromptContentOption = .value0
    ) {
        FxNimbus.shared.features.touFeature.with { _, _ in
            return TouFeature(
                contentOption: contentOption,
                enableDragToDismiss: enableDragToDismiss,
                maxRemindersCount: Int(maxRemindersCount),
                status: isEnabled
            )
        }
    }

    private func setNormalTimeout() {
        UserDefaults.standard.set(
            TermsOfUseTimeoutOption.normal.rawValue,
            forKey: PrefsKeys.FasterTermsOfUseTimeoutOverride
        )
    }
}

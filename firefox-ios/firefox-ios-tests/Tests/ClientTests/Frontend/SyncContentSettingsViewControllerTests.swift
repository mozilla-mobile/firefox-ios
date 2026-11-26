// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
@testable import Client

import XCTest
import Common
import Shared
import UIKit

@MainActor
class SyncContentSettingsViewControllerTests: XCTestCase {
    private var featureFlags: MockNimbusFeatureFlags!
    var profile: MockProfile!
    var syncContentSettingsVC: SyncContentSettingsViewController?
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        featureFlags = MockNimbusFeatureFlags()
        DependencyHelperMock().bootstrapDependencies(injectedFeatureFlagProvider: featureFlags)
        profile = makeProfile()
        syncContentSettingsVC = SyncContentSettingsViewController(windowUUID: windowUUID)
        syncContentSettingsVC?.profile = profile
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        featureFlags = nil
        profile = nil
        syncContentSettingsVC = nil
        try await super.tearDown()
    }

    func test_disconnectSetting_withUpdatedStringsEnabled_usesNewButtonTitle() throws {
        featureFlags.enabledFlags = [.syncStringUpdates]
        let settings = try XCTUnwrap(syncContentSettingsVC)
        let subject = DisconnectSetting(settings: settings)

        XCTAssertEqual(subject.title?.string, String.Settings.Disconnect.ButtonTitle)
    }

    func test_disconnectSetting_withUpdatedStringsDisabled_usesExistingButtonTitle() throws {
        let settings = try XCTUnwrap(syncContentSettingsVC)
        let subject = DisconnectSetting(settings: settings)

        XCTAssertEqual(subject.title?.string, String.SettingsDisconnectSyncButton)
    }

    func test_disconnectSetting_withUpdatedStringsEnabled_presentsNewModalCopy() throws {
        featureFlags.enabledFlags = [.syncStringUpdates]
        let settings = try XCTUnwrap(syncContentSettingsVC)
        let subject = DisconnectSetting(settings: settings)
        let navigationController = DisconnectNavigationControllerSpy()

        subject.onClick(navigationController)

        let alert = try XCTUnwrap(navigationController.presentedAlert)
        XCTAssertEqual(alert.title, String.Settings.Disconnect.AlertTitle)
        XCTAssertEqual(alert.message, String(format: .Settings.Disconnect.AlertBody, AppName.shortName.rawValue))
        XCTAssertEqual(alert.actions.first?.title, String.SettingsDisconnectCancelAction)
        XCTAssertEqual(alert.actions.last?.title, String.SettingsDisconnectDestructiveAction)
        XCTAssertEqual(alert.actions.last?.style, .destructive)
    }

    func test_disconnectSetting_withUpdatedStringsDisabled_presentsExistingModalCopy() throws {
        let settings = try XCTUnwrap(syncContentSettingsVC)
        let subject = DisconnectSetting(settings: settings)
        let navigationController = DisconnectNavigationControllerSpy()

        subject.onClick(navigationController)

        let alert = try XCTUnwrap(navigationController.presentedAlert)
        XCTAssertEqual(alert.title, String.SettingsDisconnectSyncAlertTitle)
        XCTAssertEqual(alert.message, String.SettingsDisconnectSyncAlertBody)
    }

    func test_syncContentSettingsViewController_doesNotLeak_whenGeneratedSettingsAreStored() {
        let subject = SyncContentSettingsViewController(windowUUID: windowUUID)
        subject.profile = profile
        trackForMemoryLeaks(subject)
        // Mirrors viewWillAppear(_:), which retains the generated settings on the controller.
        subject.settings = subject.generateSettings()
    }

    func test_syncContentSettingsViewController_generateSettingsCount() {
        let settingSections = syncContentSettingsVC?.generateSettings()
        // Count should be 4 as the sections contains
        // - manageSection [0]
        // - enginesSection [1]
        // - deviceNameSection [2]
        // - disconnectSection [3]
        XCTAssertEqual(settingSections?.count, 4)
    }

    func test_syncContentSettingsViewController_engineSectionForSettings() {
        let settingSections = syncContentSettingsVC?.generateSettings()
        let engineSectionChildren = settingSections?[1].children
        // Count for engine section children should be 5
        // as the sub engine section contains
        // bookmarks
        // history
        // tabs
        // passwords
        // credit cards
        XCTAssertEqual(engineSectionChildren?.count, 6)
    }
}

private final class DisconnectNavigationControllerSpy: UINavigationController {
    private(set) var presentedAlert: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        presentedAlert = viewControllerToPresent as? UIAlertController
    }
}

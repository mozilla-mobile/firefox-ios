// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import Shared
import Common

class VersionSettingTests: XCTestCase {
    private var delegate: MockDebugSettingsDelegate!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
        delegate = MockDebugSettingsDelegate()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        delegate = nil
    }

    func testCopyAppVersion() {
        // Given
        let settingsTable = SettingsTableViewController(style: .grouped, windowUUID: windowUUID)
        let navigationController = UINavigationController(rootViewController: settingsTable)
        let versionSetting = VersionSetting(settingsDelegate: delegate)
        versionSetting.theme = DefaultThemeManager(
            sharedContainerIdentifier: AppInfo.sharedContainerIdentifier
        ).getCurrentTheme(for: windowUUID)

        // When
        versionSetting.onLongPress(navigationController)

        // Then
        let appVersionString = UIPasteboard.general.string
        let appVersionPredicate = (appVersionString?.contains("Firefox") ?? false) == true
        XCTAssertNotNil(appVersionString, "App version not copied")
        XCTAssert(appVersionPredicate, "Pasteboard doesn't contain app version")
    }

    func testAppVersionClick() {
        // Given
        let settingsTable = SettingsTableViewController(style: .grouped, windowUUID: windowUUID)
        let navigationController = UINavigationController(rootViewController: settingsTable)
        let versionSetting = VersionSetting(settingsDelegate: delegate)

        // When
        versionSetting.onClick(navigationController)

        // Then
        XCTAssertEqual(delegate.pressedVersionCalled, 1)
    }
}

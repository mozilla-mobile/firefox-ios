// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import Shared

class VersionSettingTests: XCTestCase {
    private var delegate: MockAppSettingsDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        delegate = MockAppSettingsDelegate()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        delegate = nil
    }

    func testCopyAppVersion() {
        // Given
        let settingsTable = SettingsTableViewController(style: .grouped)
        let navigationController = UINavigationController(rootViewController: settingsTable)
        let versionSetting = VersionSetting(settings: settingsTable, appSettingsDelegate: delegate)
        versionSetting.theme = DefaultThemeManager().currentTheme

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
        let settingsTable = SettingsTableViewController(style: .grouped)
        let navigationController = UINavigationController(rootViewController: settingsTable)
        let versionSetting = VersionSetting(settings: settingsTable, appSettingsDelegate: delegate)

        // When
        versionSetting.onClick(navigationController)

        // Then
        XCTAssertEqual(delegate.clickedVersionCalled, 1)
    }
}

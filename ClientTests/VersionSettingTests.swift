// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import Client

class VersionSettingTests: XCTestCase {

    func testCopyAppVersion() {
        // MARK: - given
        let settingsTable = SettingsTableViewController(style: .grouped)
        let navigationController = UINavigationController(rootViewController: settingsTable)
        let versionSetting = VersionSetting(settings: settingsTable)
        
        // MARK: - when
        versionSetting.onLongPress(navigationController)
        
        // MARK: - then
        let appVersionString = UIPasteboard.general.string
        let appVersionPredicate = (appVersionString?.contains("Firefox Daylight") ?? false) == true
        XCTAssertNotNil(appVersionString, "App version not copied")
        XCTAssert(appVersionPredicate, "Pasteboard doesn't contain app version")
    }

}

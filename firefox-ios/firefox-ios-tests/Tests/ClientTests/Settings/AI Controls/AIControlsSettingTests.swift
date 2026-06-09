// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
class AIControlsSettingTests: XCTestCase {
    let delegate = MockGeneralSettingsDelegate()
    let settings = SettingsTableViewController(
        style: .plain,
        windowUUID: .XCTestDefaultUUID,
        themeManager: MockThemeManager()
    )
    var aiControlsSetting: AIControlsSetting?

    func testInit() {
        aiControlsSetting = AIControlsSetting(settings: settings, settingsDelegate: delegate)
        XCTAssertEqual(aiControlsSetting?.title?.string, "AI Controls")
    }

    func testOnClick() {
        aiControlsSetting = AIControlsSetting(settings: settings, settingsDelegate: delegate)
        aiControlsSetting?.onClick(nil)
        XCTAssertTrue(delegate.pressedAIControlsCalled)
    }
}

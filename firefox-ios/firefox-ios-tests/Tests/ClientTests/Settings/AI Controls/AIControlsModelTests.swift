// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

class AIControlsModelTests: XCTest {
    var mockPrefs: MockProfilePrefs!

    override func setUp() {
        mockPrefs = MockProfilePrefs(things: [
            PrefsKeys.Summarizer.summarizeContentFeature: true,
            PrefsKeys.Settings.translationsFeature: false,
            PrefsKeys.Settings.aiKillSwitchFeature: true
        ], prefix: "")
    }

    func testInitialize() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel.killSwitchIsOn)
        XCTAssertTrue(aiControlsModel.pageSummariesEnabled)
        XCTAssertFalse(aiControlsModel.translationEnabled)
    }

    func testToggleKillSwitchOn() {
        mockPrefs = MockProfilePrefs(things: [
            PrefsKeys.Summarizer.summarizeContentFeature: true,
            PrefsKeys.Settings.translationsFeature: false,
            PrefsKeys.Settings.aiKillSwitchFeature: false
        ], prefix: "")
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        aiControlsModel.toggleKillSwitch(to: true)

        XCTAssertTrue(aiControlsModel.killSwitchToggledOn)
        XCTAssertFalse(aiControlsModel.pageSummariesEnabled)
        XCTAssertFalse(aiControlsModel.translationEnabled)
        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.translationsFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }
    }

    func testToggleKillSwitchOff() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        aiControlsModel.toggleKillSwitch(to: false)
        XCTAssertFalse(aiControlsModel.killSwitchIsOn)
        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.translationsFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }

        XCTAssertTrue(aiControlsModel.pageSummariesEnabled)
        XCTAssertTrue(aiControlsModel.translationEnabled)
    }
}

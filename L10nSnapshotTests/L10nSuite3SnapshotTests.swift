/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nSuite3SnapshotTests: L10nBaseSnapshotTests {
    private func typePasscode(n: Int, keyNumber: Int) {
        for _ in 1...n {
            app.keys.element(boundBy: keyNumber).tap()
            sleep(1)
        }
    }

    func testPasscodeSettings() {
        navigator.goto(PasscodeSettings)
        app.tables.cells["TurnOnPasscode"].tap()
        snapshot("SetPasscodeScreen-1-nopasscode")
        
        // Type "111111 passcode"
        typePasscode(n: 6, keyNumber: 2)
        snapshot("SetPasscodeScreen-2-typepasscode")
        // Type incorrect passcode "111112"
        typePasscode(n: 5, keyNumber: 2)
        // Type once inkey "2"
        typePasscode(n: 1, keyNumber: 1)
        snapshot("SetPasscodeScreen-3-passcodesmustmatch")
        
        // Confitm passcode
        typePasscode(n: 6, keyNumber: 2)
        typePasscode(n: 6, keyNumber: 2)
        snapshot("SetPasscodeScreen-3")
        
        // Go to interval settings
        app.tables.cells["PasscodeInterval"].tap()
        typePasscode(n: 6, keyNumber: 2)
        snapshot("PasscodeIntervalScreen-1")
    }
    
    func testDefaultTopSites() {
        navigator.goto(HomePanelsScreen)
        snapshot("DefaultTopSites-01")
    }

    func testMenuOnTopSites() {
        navigator.goto(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnTopSites-01")
    }

    func testSettings() {
        let table = app.tables.element(boundBy: 0)
        navigator.goto(SettingsScreen)
        table.forEachScreen { i in
            snapshot("Settings-main-\(i)")
        }

        allSettingsScreens.forEach { nodeName in
            self.navigator.goto(nodeName)
            table.forEachScreen { i in
                snapshot("Settings-\(nodeName)-\(i)")
            }
        }
    }

    func testPrivateBrowsingTabsEmptyState() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        app.tables.cells.element(boundBy: 0).buttons["closeTabButtonTabTray"].tap()
        snapshot("PrivateBrowsingTabsEmptyState-01")
    }
}

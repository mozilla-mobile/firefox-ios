/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client

class PrivateModeAuthenticationTests: KIFTestCase {

    private func getBrowserViewController() -> BrowserViewController {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).browserViewController
    }
    
    private func enablePasscodeAuthentication() {
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Passcode")
        if (try? tester().tryFindingTappableViewWithAccessibilityLabel("Turn Passcode On")) != nil {
            // If passcode access is currently switched off
            tester().enterTextIntoCurrentFirstResponder("11111111")
        }
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testPasscodeAuthenticationFromTabTray() {
        enablePasscodeAuthentication()
        let bvc = getBrowserViewController()
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        XCTAssertFalse(bvc.tabManager.isInPrivateMode)
        tester().tapViewWithAccessibilityLabel("Private Mode")
        XCTAssertFalse(bvc.tabManager.isInPrivateMode)
        tester().enterTextIntoCurrentFirstResponder("11111111")
        tester().waitForAnimationsToFinish()
        XCTAssertTrue(bvc.tabManager.isInPrivateMode)
    }
}

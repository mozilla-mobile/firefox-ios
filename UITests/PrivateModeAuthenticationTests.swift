/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftKeychainWrapper
@testable import Client

@available(iOS 9, *)
class PrivateModeAuthenticationTests: KIFTestCase {

    private var webRoot: String!
    private static let passcode = "0000"
    
    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        super.tearDown()
        PasscodeUtils.resetPasscode()
        BrowserUtils.resetToAboutHome(tester())
    }
    
    private func getAppDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }

    private func getBrowserViewController() -> BrowserViewController {
        return getAppDelegate().browserViewController
    }

    private func enablePasscodeAuthentication() {
        PasscodeUtils.setPasscode(PrivateModeAuthenticationTests.passcode, interval: .Immediately)
    }

    private func checkBrowsingMode(isPrivate isPrivate: Bool) {
        let bvc = getBrowserViewController()
        tester().waitForAnimationsToFinish()
        XCTAssert(isPrivate ? bvc.tabManager.isInPrivateMode : !bvc.tabManager.isInPrivateMode)
    }

    private func enterCorrectPasscode() {
        checkBrowsingMode(isPrivate: false)
        tester().enterTextIntoCurrentFirstResponder(PrivateModeAuthenticationTests.passcode)
        tester().waitForAnimationsToFinish()
        checkBrowsingMode(isPrivate: true)
    }
    
    private func checkActionEnablesPrivateBrowsingMode(action: () -> ()) {
        enablePasscodeAuthentication()
        checkBrowsingMode(isPrivate: false)
        action()
        enterCorrectPasscode()
    }

    func testPasscodeAuthenticationFromTabTray() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        checkActionEnablesPrivateBrowsingMode() {
            self.tester().tapViewWithAccessibilityLabel("Private Mode")
        }
    }

    func testPasscodeAuthenticationFromTopTabs() {
        let bvc = getBrowserViewController()
        guard bvc.shouldShowTopTabsForTraitCollection(bvc.traitCollection) else {
            return
        }
        checkActionEnablesPrivateBrowsingMode() {
            self.tester().tapViewWithAccessibilityLabel("Private Tab")
        }
    }

    func testPasscodeAuthenticationForNewPrivateTab() {
        tester().tapViewWithAccessibilityLabel("Menu")
        checkActionEnablesPrivateBrowsingMode() {
            self.tester().tapViewWithAccessibilityLabel("New Private Tab")
        }
    }
    
    func testPasscodeAuthenticationForNewPrivateTabFromTabTray() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Menu")
        checkActionEnablesPrivateBrowsingMode() {
            self.tester().tapViewWithAccessibilityLabel("New Private Tab")
        }
    }
    
    func testPasscodeAuthenticationForNewPrivateTabFromTodayView() {
        checkActionEnablesPrivateBrowsingMode() {
            self.getAppDelegate().launchFromURL(LaunchParams(url: NSURL(string: "\(self.webRoot)/numberedPage.html?page=1"), isPrivate: true))
        }
    }
    
    func testPassCodeAuthenticationForNewPrivateTabFrom3DTouchQuickAction() {
        checkActionEnablesPrivateBrowsingMode() {
            QuickActions.sharedInstance.handleOpenNewTab(withBrowserViewController: self.getBrowserViewController(), isPrivate: true)
        }
    }
}

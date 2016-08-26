/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftKeychainWrapper
@testable import Client

@available(iOS 9, *)
class PrivateModeAuthenticationTests: KIFTestCase {

    private var webRoot: String!
    private static let passcode = "0000"
    private static let incorrectPasscode = String(PrivateModeAuthenticationTests.passcode.characters.map { Character("\(9 - Int(String($0))!)") })
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
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
        assert(isPrivate ? bvc.tabManager.isInPrivateMode : !bvc.tabManager.isInPrivateMode)
        XCTAssertTrue(isPrivate ? bvc.tabManager.isInPrivateMode : !bvc.tabManager.isInPrivateMode)
    }

    private func enterPasscode(passcode: String) {
        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        tester().enterTextIntoCurrentFirstResponder(passcode)
        tester().waitForAnimationsToFinish()
    }

    private func enterCorrectPasscode(andExpectToEnterPrivateMode enterPrivateMode: Bool = true) {
        enterPasscode(PrivateModeAuthenticationTests.passcode)
        checkBrowsingMode(isPrivate: enterPrivateMode)
    }

    private func enterIncorrectPasscode() {
        enterPasscode(PrivateModeAuthenticationTests.incorrectPasscode)
        checkBrowsingMode(isPrivate: false)
    }

    private func checkActionEnablesPrivateBrowsingMode(action: () -> ()) {
        enablePasscodeAuthentication()
        checkBrowsingMode(isPrivate: false)
        action()
        enterIncorrectPasscode()
        enterCorrectPasscode()
    }

    func testPasscodeAuthenticationFromTabTray() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        checkActionEnablesPrivateBrowsingMode() {
            self.tester().tapViewWithAccessibilityLabel("Private Mode")
        }
    }
    
    func testRepeatedPasscodeAuthentications() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        checkActionEnablesPrivateBrowsingMode() {
            self.tester().tapViewWithAccessibilityLabel("Private Mode")
        }
        self.tester().tapViewWithAccessibilityLabel("Private Mode")
        checkBrowsingMode(isPrivate: false)
        checkActionEnablesPrivateBrowsingMode() {
            self.tester().tapViewWithAccessibilityLabel("Private Mode")
        }
        
    }

    func testPasscodeAuthenticationFromTopTabs() {
        let bvc = getBrowserViewController()
        guard bvc.shouldShowTopTabsForTraitCollection(bvc.traitCollection) else {
            return
        }
        checkActionEnablesPrivateBrowsingMode {
            self.tester().tapViewWithAccessibilityLabel("Private Tab")
        }
    }

    func testPasscodeAuthenticationForNewPrivateTab() {
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().waitForAnimationsToFinish()
        checkActionEnablesPrivateBrowsingMode {
            self.tester().tapViewWithAccessibilityLabel("New Private Tab")
        }
    }

    func testPasscodeAuthenticationForNewPrivateTabFromTabTray() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Menu")
        checkActionEnablesPrivateBrowsingMode {
            self.tester().tapViewWithAccessibilityLabel("New Private Tab")
        }
    }

    func testPasscodeAuthenticationForNewPrivateTabFromTodayView() {
        checkActionEnablesPrivateBrowsingMode {
            self.getAppDelegate().launchFromURL(LaunchParams(url: NSURL(string: "\(self.webRoot)/pageWithLink.html"), isPrivate: true))
        }
    }
    
    func testPasscodeAuthenticationForNewPrivateTabFrom3DTouchQuickAction() {
        checkActionEnablesPrivateBrowsingMode() {
            QuickActions.sharedInstance.handleOpenNewTab(withBrowserViewController: self.getBrowserViewController(), isPrivate: true)
        }
    }

    func testPasscodeAuthenticationWhenOpeningLinkInPrivateTab() {
        let url = "\(self.webRoot)/pageWithLink.html"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        let longPressDuration: NSTimeInterval = 0.5
        tester().longPressWebViewElementWithAccessibilityLabel("Reflexive Link", duration: longPressDuration)
        enablePasscodeAuthentication()
        checkBrowsingMode(isPrivate: false)
        tester().tapViewWithAccessibilityLabel("Open in New Private Tab")
        enterIncorrectPasscode()
        enterCorrectPasscode(andExpectToEnterPrivateMode: false)
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        checkActionEnablesPrivateBrowsingMode {
            self.tester().tapViewWithAccessibilityLabel("Private Mode")
        }
        let tabsView = tester().waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView
        XCTAssertEqual(tabsView.numberOfItemsInSection(0), 1)
    }
    
    private func checkCorrectBehaviourWhenBackgrounded() {
        tester().deactivateAppForDuration(1)
        checkBrowsingMode(isPrivate: true)
        enterCorrectPasscode()
        checkBrowsingMode(isPrivate: true)
        tester().deactivateAppForDuration(1)
        tester().tapViewWithAccessibilityLabel("Cancel")
        checkBrowsingMode(isPrivate: false)
    }
    
    func testPasscodeAuthenticationWhenBackgroundedInWebPage() {
        testPasscodeAuthenticationForNewPrivateTab()
        checkCorrectBehaviourWhenBackgrounded()
    }
    
    func testPasscodeAuthenticationWhenBackgroundedInTabTray() {
        testPasscodeAuthenticationFromTabTray()
        checkCorrectBehaviourWhenBackgrounded()
    }
}

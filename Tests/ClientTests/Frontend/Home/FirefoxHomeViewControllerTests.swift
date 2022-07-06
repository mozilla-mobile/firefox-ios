// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest

class FirefoxHomeViewControllerTests: XCTestCase {

    func testFirefoxHomeViewController_creationFromBVC_hasNoLeaks() {
        let profile = MockProfile()
        let tabManager = TabManager(profile: profile, imageStore: nil)
        let browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)

        browserViewController.addSubviews()
        browserViewController.showFirefoxHome(inline: true)

        // BVC cannot be uninstanciated at the moment. This is an issue to fix
//        trackForMemoryLeaks(browserViewController)
        trackForMemoryLeaks(browserViewController.firefoxHomeViewController!)

        let expectation = self.expectation(description: "Firefox home page has finished animation")

        browserViewController.hideFirefoxHome {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testFirefoxHomeViewController_simpleCreation_hasNoLeaks() {
        let profile = MockProfile()
        let tabManager = TabManager(profile: profile, imageStore: nil)
        let firefoxHomeViewController = HomepageViewController(profile: profile, tabManager: tabManager)

        trackForMemoryLeaks(firefoxHomeViewController)
    }
}

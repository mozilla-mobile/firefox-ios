// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest
import Common

class HomepageViewControllerTests: XCTestCase {
    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
    }

    func testHomepageViewController_creationFromBVC_nilByDefault() {
        let tabManager = TabManager(profile: profile, imageStore: nil)
        let browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.addSubviews()
        XCTAssertNil(browserViewController.homepageViewController, "Homepage is nil on creation")
    }

    func testHomepageViewController_creationFromBVC_hideDoesntNil() {
        let tabManager = TabManager(profile: profile, imageStore: nil)
        let browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)

        browserViewController.addSubviews()
        browserViewController.showHomepage(inline: true)

        let expectation = self.expectation(description: "Firefox home page has finished animation")

        browserViewController.hideHomepage {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertNotNil(browserViewController.homepageViewController, "Homepage isn't nil after hiding it")
    }

    func testHomepageViewController_simpleCreation_hasNoLeaks() {
        let tabManager = TabManager(profile: profile, imageStore: nil)
        let urlBar = URLBarView(profile: profile)
        let overlayManager = MockOverlayModeManager()

        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)

        let firefoxHomeViewController = HomepageViewController(profile: profile,
                                                               tabManager: tabManager,
                                                               urlBar: urlBar,
                                                               overlayManager: overlayManager)

        trackForMemoryLeaks(firefoxHomeViewController)
    }

    // MARK: - UpdateInContentHomePanel

    func testUpdateInContentHomePanel_nilURL_doesntShowHomepage() {
        let tabManager = TabManager(profile: profile, imageStore: nil)
        let browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.addSubviews()

        browserViewController.updateInContentHomePanel(nil)

        XCTAssertNil(browserViewController.homepageViewController, "Homepage isn't shown")
    }

    func testUpdateInContentHomePanel_homeURL_showHomepage() {
        let tabManager = TabManager(profile: profile, imageStore: nil)
        let browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.addSubviews()

        let aboutHomeURL = URL(string: "internal://local/sessionrestore?url=internal://local/about/home")!
        browserViewController.updateInContentHomePanel(aboutHomeURL)

        XCTAssertNotNil(browserViewController.homepageViewController, "Homepage is shown")
    }

    func testUpdateInContentHomePanel_notHomeURL_doesntShowHomepage() {
        let tabManager = TabManager(profile: profile, imageStore: nil)
        let browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.addSubviews()

        let notHomeURL = URL(string: "www.google.com")!
        browserViewController.updateInContentHomePanel(notHomeURL)

        XCTAssertNil(browserViewController.homepageViewController, "Homepage isn't shown")
    }
}

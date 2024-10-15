// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest
import Common

class LegacyHomepageViewControllerTests: XCTestCase {
    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
        Experiments.events.clearEvents()
    }

    func testHomepageViewController_simpleCreation_hasNoLeaks() {
        let tabManager = TabManagerImplementation(profile: profile,
                                                  uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        let urlBar = URLBarView(profile: profile, windowUUID: .XCTestDefaultUUID)
        let overlayManager = MockOverlayModeManager()
        overlayManager.setURLBar(urlBarView: urlBar)

        let firefoxHomeViewController = LegacyHomepageViewController(
            profile: profile,
            toastContainer: UIView(),
            tabManager: tabManager,
            overlayManager: overlayManager
        )

        trackForMemoryLeaks(firefoxHomeViewController)
    }

    func testHomepage_viewWillAppear_sendsBehavioralTargetingEvent() {
        Experiments.events.clearEvents()
        let tabManager = TabManagerImplementation(profile: profile,
                                                  uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        let urlBar = URLBarView(profile: profile, windowUUID: .XCTestDefaultUUID)
        let overlayManager = MockOverlayModeManager()
        overlayManager.setURLBar(urlBarView: urlBar)

        let subject = LegacyHomepageViewController(
            profile: profile,
            toastContainer: UIView(),
            tabManager: tabManager,
            overlayManager: overlayManager
        )
        XCTAssertFalse(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'homepage_viewed'|eventSum('Days', 1, 0) > 0"
            )
        )
        subject.viewWillAppear(false)
        let expectation = self.expectation(description: "Record event called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
            guard let hasValue = try? Experiments.createJexlHelper()!.evalJexl(
                expression: "'homepage_viewed'|eventSum('Days', 1, 0) > 0"
            ) else {
                XCTFail("should not be nil")
                return
            }
            XCTAssertTrue(hasValue)
        }
        waitForExpectations(timeout: 1)
    }
}

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
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile = nil
    }

    func testHomepageViewController_simpleCreation_hasNoLeaks() {
        let tabManager = LegacyTabManager(profile: profile, imageStore: nil)
        let urlBar = URLBarView(profile: profile)
        let overlayManager = MockOverlayModeManager()
        overlayManager.setURLBar(urlBarView: urlBar)

        let firefoxHomeViewController = HomepageViewController(profile: profile,
                                                               toastContainer: UIView(),
                                                               tabManager: tabManager,
                                                               overlayManager: overlayManager)

        trackForMemoryLeaks(firefoxHomeViewController)
    }
}

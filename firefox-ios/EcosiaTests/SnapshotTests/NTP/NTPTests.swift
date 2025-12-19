// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import Ecosia
import Common
@testable import Client

final class NTPTests: SnapshotBaseTests {

    func testNTPShowingImpactIntro() {
        User.shared.showImpactIntro()
        snapshotNTP(impactIntroShown: true)
    }

    func testNTPImpactIntroHidden() {
        User.shared.hideImpactIntro()
        snapshotNTP(impactIntroShown: false)
    }
}

extension NTPTests {
    fileprivate func snapshotNTP(impactIntroShown: Bool) {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let urlBar = URLBarView(profile: self.profile, windowUUID: .snapshotTestDefaultUUID)
            let overlayManager = MockOverlayModeManager()
            overlayManager.setURLBar(urlBarView: urlBar)

            let homePageViewController = LegacyHomepageViewController(profile: self.profile,
                                                                      toastContainer: UIView(),
                                                                      tabManager: MockTabManager(),
                                                                      overlayManager: overlayManager,
                                                                      referrals: .init(),
                                                                      delegate: nil,
                                                                      auth: EcosiaAuth(browserViewController: BrowserViewController(profile: self.profile, tabManager: MockTabManager())))
            return homePageViewController
        },
                                          // Precision at .95 to accommodate a snapshot looking slightly different due to the different data output
                                          // from the statistics json
                                          precision: 0.95,
                                          testName: impactIntroShown ? "NTP_with_impact_intro" : "NTP_without_impact_intro")
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
@testable import Client

import XCTest
import Common

class SyncContentSettingsViewControllerTests: XCTestCase {
    var profile: MockProfile!
    var syncContentSettingsVC: SyncContentSettingsViewController?
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        syncContentSettingsVC = SyncContentSettingsViewController(windowUUID: windowUUID)
        syncContentSettingsVC?.profile = profile
    }

    override func tearDown() {
        AppContainer.shared.reset()
        profile = nil
        syncContentSettingsVC = nil
        super.tearDown()
    }

    func test_syncContentSettingsViewController_generateSettingsCount() {
        let settingSections = syncContentSettingsVC?.generateSettings()
        // Count should be 4 as the sections contains
        // - manageSection [0]
        // - enginesSection [1]
        // - deviceNameSection [2]
        // - disconnectSection [3]
        XCTAssertEqual(settingSections?.count, 4)
    }

    func test_syncContentSettingsViewController_engineSectionForSettings() {
        let settingSections = syncContentSettingsVC?.generateSettings()
        let engineSectionChildren = settingSections?[1].children
        // Count for engine section children should be 5
        // as the sub engine section contains
        // bookmarks
        // history
        // tabs
        // passwords
        // credit cards
        XCTAssertEqual(engineSectionChildren?.count, 6)
    }
}

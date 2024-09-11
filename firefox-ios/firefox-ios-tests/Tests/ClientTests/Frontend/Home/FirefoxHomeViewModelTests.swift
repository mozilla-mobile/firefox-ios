// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared
@testable import Client

class FirefoxHomeViewModelTests: XCTestCase {
    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        // Clean user defaults to avoid having flaky test changing the section count
        // because message card reach max amount of impressions
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
        AppContainer.shared.reset()
    }

    // MARK: Number of sections

    func testNumberOfSection_withoutUpdatingData_has2Sections() {
        let viewModel = HomepageViewModel(profile: profile,
                                          isPrivate: false,
                                          tabManager: MockTabManager(),
                                          theme: LightTheme())
        XCTAssertEqual(viewModel.shownSections.count, 2)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.homepageHeader)
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.customizeHome)
    }
}

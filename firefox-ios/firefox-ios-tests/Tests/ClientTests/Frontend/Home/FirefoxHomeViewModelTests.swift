// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared
@testable import Client
@testable import Ecosia

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
                                          // Ecosia: Add referrals
                                          referrals: Referrals(),
                                          theme: LightTheme())
        /* Ecosia: Udpate number of sections
        XCTAssertEqual(viewModel.shownSections.count, 2)
         */
        XCTAssertEqual(viewModel.shownSections.count, 4)
        XCTAssertEqual(viewModel.shownSections[0], HomepageSectionType.homepageHeader)
        /* Ecosia: Update section type
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.customizeHome)
         */
        XCTAssertEqual(viewModel.shownSections[1], HomepageSectionType.libraryShortcuts)
    }
}

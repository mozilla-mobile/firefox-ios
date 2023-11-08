// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

class LibraryViewModelTests: XCTestCase {
    private var subject: LibraryViewModel!
    private var profile: MockProfile!
    private var tabManager: TabManager!

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(databasePrefix: "historyHighlights_tests")
        profile.reopen()
        tabManager = TabManagerImplementation(profile: profile, imageStore: nil)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile.shutdown()
        profile = nil
        tabManager = nil
    }

    func testInitialState_Init() {
        subject = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        subject.selectedPanel = .bookmarks

        XCTAssertEqual(subject.panelDescriptors.count, 4)
    }

    func testLibraryPanelTitle() {
        subject = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        subject.selectedPanel = .bookmarks

        for panel in subject.panelDescriptors {
            switch panel.panelType {
            case .bookmarks:
                XCTAssertEqual(panel.panelType.title, .AppMenu.AppMenuBookmarksTitleString)
            case .history:
                XCTAssertEqual(panel.panelType.title, .AppMenu.AppMenuHistoryTitleString)
            case .downloads:
                XCTAssertEqual(panel.panelType.title, .AppMenu.AppMenuDownloadsTitleString)
            case .readingList:
                XCTAssertEqual(panel.panelType.title, .AppMenu.AppMenuReadingListTitleString)
            }
        }
    }
}

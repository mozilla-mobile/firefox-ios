// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

class LibraryViewModelTests: XCTestCase {
    private var subject: LibraryViewModel!
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(databasePrefix: "historyHighlights_tests")
        profile.reopen()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        AppContainer.shared.reset()
        profile.shutdown()
        profile = nil
        super.tearDown()
    }

    func testInitialState_Init() {
        subject = LibraryViewModel(withProfile: profile)
        subject.selectedPanel = .bookmarks

        XCTAssertEqual(subject.panelDescriptors.count, 4)
    }

    func testLibraryPanelTitle() {
        subject = LibraryViewModel(withProfile: profile)
        subject.selectedPanel = .bookmarks

        for panel in subject.panelDescriptors {
            switch panel.panelType {
            case .bookmarks:
                XCTAssertEqual(panel.panelType.title, .LegacyAppMenu.AppMenuBookmarksTitleString)
            case .history:
                XCTAssertEqual(panel.panelType.title, .LegacyAppMenu.AppMenuHistoryTitleString)
            case .downloads:
                XCTAssertEqual(panel.panelType.title, .LegacyAppMenu.AppMenuDownloadsTitleString)
            case .readingList:
                XCTAssertEqual(panel.panelType.title, .LegacyAppMenu.AppMenuReadingListTitleString)
            }
        }
    }
}

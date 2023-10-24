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

        XCTAssertTrue(subject.currentPanelState == .bookmarks(state: .mainView))
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

    // MARK: - Bookmarks

    func testBookmarksButtons_MainFolder() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
        XCTAssertEqual(toolbarItems[1].title, "Edit")
    }

    func testBookmarksButtons_SubFolder() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
        XCTAssertEqual(toolbarItems[1].title, "Edit")
    }

    func testBookmarks_FolderEditMode() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        panel.enableEditMode()

        XCTAssertEqual(subject.currentPanelState, .bookmarks(state: .inFolderEditMode))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 3, "Expected Add, Done button and flexibleSpace")
    }

    func testBookmarks_ItemEditMode() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        panel.presentInFolderActions()
        panel.handleItemEditMode()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 3, "Expected Edit button and flexibleSpace")
    }

    func testBookmarks_MainFolderLeavingEdit() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        panel.disableEditMode()

        XCTAssertEqual(subject.currentPanelState, .bookmarks(state: .mainView))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
    }

    func testBookmarksBack_ForInFolder() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        panel.handleLeftTopButton()

        XCTAssertEqual(subject.currentPanelState, .bookmarks(state: .mainView))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
    }

    func testBookmarksBack_ForItemEditMode() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        panel.handleLeftTopButton()

        XCTAssertEqual(subject.currentPanelState, .bookmarks(state: .inFolderEditMode))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 3, "Expected Edit button and flexibleSpace")
    }

    func testBookmarksShouldDismissOnDone_ForMain() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .mainView))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testBookmarksShouldDismissOnDone_ForInFolder() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testBookmarksShouldDismissOnDone_ForFolderEditMode() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testBookmarksShouldDismissOnDone_ForItemEditMode() {
        setup(panelType: .bookmarks)
        guard let panel = subject.currentPanel as? BookmarksPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        XCTAssertFalse(panel.shouldDismissOnDone())
    }

    // MARK: - HistoryPanel
    func testHistoryButtons() {
        setup(panelType: .history)

        guard let panel = subject.currentPanel as? HistoryPanel else {
            XCTFail("Expected history panel")
            return
        }

        XCTAssertTrue(subject.currentPanelState == .history(state: .mainView))
        // There is 2 flexible space to keep buttons to the left
        XCTAssertEqual(panel.bottomToolbarItems.count, 4, "Expected Delete, Search buttons and 2 flexible spaces")
    }

    func testHistorySearch_ForStartSearch() {
        setup(panelType: .history)
        guard let panel = subject.currentPanel as? HistoryPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .history(state: .mainView))
        panel.startSearchState()

        XCTAssertEqual(subject.currentPanelState, .history(state: .search))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 4, "Expected Edit button and flexibleSpace")
    }

    func testHistorySearch_ForExitSearch() {
        setup(panelType: .history)
        guard let panel = subject.currentPanel as? HistoryPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .history(state: .search))
        panel.handleRightTopButton()

        XCTAssertEqual(subject.currentPanelState, .history(state: .mainView))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 4, "Expected Edit button and flexibleSpace")
    }

    func testHistoryInFolder() {
        setup(panelType: .history)
        guard let panel = subject.currentPanel as? HistoryPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .history(state: .inFolder))
        XCTAssertTrue(panel.bottomToolbarItems.isEmpty, "Expected Edit button and flexibleSpace")
    }

    func testHistoryMain_ForBackButtonPress() {
        setup(panelType: .history)
        guard let panel = subject.currentPanel as? HistoryPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .history(state: .inFolder))
        panel.handleLeftTopButton()

        XCTAssertEqual(subject.currentPanelState, .history(state: .mainView))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 4, "Expected Edit button and flexibleSpace")
    }

    func testHistoryShouldDismissOnDone_ForSearch() {
        setup(panelType: .history)
        guard let panel = subject.currentPanel as? HistoryPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .history(state: .search))
        XCTAssertFalse(panel.shouldDismissOnDone())
    }

    func testHistoryShouldDismissOnDone_ForMain() {
        setup(panelType: .history)
        guard let panel = subject.currentPanel as? HistoryPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .history(state: .mainView))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testHistoryShouldDismissOnDone_ForInFolder() {
        setup(panelType: .history)
        guard let panel = subject.currentPanel as? HistoryPanel else {
            XCTFail("Expected history panel")
            return
        }

        panel.updatePanelState(newState: .history(state: .inFolder))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    // MARK: - ReaderPanel
    func testReaderPanelButtons() {
        setup(panelType: .readingList)

        guard let panel = subject.currentPanel as? ReadingListPanel else {
            XCTFail("Expected reading list panel")
            return
        }

        XCTAssertTrue(subject.currentPanelState == .readingList)
        XCTAssertTrue(panel.bottomToolbarItems.isEmpty)
    }

    func testReaderPanel_ShouldDismissOnDone() {
        setup(panelType: .readingList)

        guard let panel = subject.currentPanel as? ReadingListPanel else {
            XCTFail("Expected reading list panel")
            return
        }

        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    // MARK: - DownloadsPanel
    func testDownloadsPanelButtons() {
        setup(panelType: .downloads)

        guard let panel = subject.currentPanel as? DownloadsPanel else {
            XCTFail("Expected downloads panel")
            return
        }

        XCTAssertTrue(subject.currentPanelState == .downloads)
        XCTAssertTrue(panel.bottomToolbarItems.isEmpty)
    }

    func testDownloadsPanel_ShouldDismissOnDone() {
        setup(panelType: .downloads)

        guard let panel = subject.currentPanel as? DownloadsPanel else {
            XCTFail("Expected reading list panel")
            return
        }

        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    // MARK: - Helper functions
    private func setup(panelType: LibraryPanelType) {
        subject = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        subject.selectedPanel = panelType
        subject.setupNavigationController()
    }
}

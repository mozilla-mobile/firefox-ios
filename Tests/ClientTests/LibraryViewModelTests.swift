// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class LibraryViewModelTests: XCTestCase {

    private var sut: LibraryViewModel!
    private var profile: MockProfile!
    private var tabManager: TabManager!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "historyHighlights_tests")
        profile._reopen()
        tabManager = TabManager(profile: profile, imageStore: nil)
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        profile = nil
        tabManager = nil
    }

    func testInitialState_Init() {
        sut = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        sut.selectedPanel = .bookmarks

        XCTAssertTrue(sut.currentPanelState == .bookmarks(state: .mainView))
        XCTAssertEqual(sut.panelDescriptors.count, 4)
    }

    func testBookmarksButtons_MainFolder() {
        sut = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        sut.selectedPanel = .bookmarks
        sut.setupNavigationController()

        guard let panel = sut.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
        XCTAssertEqual(toolbarItems[1].title, "Edit")
    }

    func testBookmarksButtons_SubFolder() {
        sut = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        sut.selectedPanel = .bookmarks
        sut.setupNavigationController()

        guard let panel = sut.currentPanel as? BookmarksPanel else {
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
        sut = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        sut.selectedPanel = .bookmarks
        sut.setupNavigationController()

        guard let panel = sut.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        panel.enableEditMode()

        XCTAssertEqual(sut.currentPanelState, .bookmarks(state: .inFolderEditMode))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 3, "Expected Add, Done button and flexibleSpace")
    }

    // TODO: Handle case
//    func testBookmarks_ItemEditMode() {
//        sut = LibraryViewModel(withProfile: profile, tabManager: tabManager)
//        sut.selectedPanel = .bookmarks
//        sut.setupNavigationController()
//
//        guard let panel = sut.currentPanel as? BookmarksPanel else {
//            XCTFail("Expected bookmark panel")
//            return
//        }
//
//        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
//        panel.enableEditMode()
//
//        XCTAssertEqual(sut.currentPanelState, .bookmarks(state: .itemEditMode))
//        let toolbarItems = panel.bottomToolbarItems
//        // We need to account for the flexibleSpace item
//        XCTAssertEqual(toolbarItems.count, 3, "Expected Add, Done button and flexibleSpace")
//    }

    func testBookmarks_SubFolderLeavingEdit() {
        sut = LibraryViewModel(withProfile: profile, tabManager: tabManager)
        sut.selectedPanel = .bookmarks
        sut.setupNavigationController()

        guard let panel = sut.currentPanel as? BookmarksPanel else {
            XCTFail("Expected bookmark panel")
            return
        }

        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        panel.disableEditMode()

        XCTAssertEqual(sut.currentPanelState, .bookmarks(state: .inFolder))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Add, Done button and flexibleSpace")
    }
}

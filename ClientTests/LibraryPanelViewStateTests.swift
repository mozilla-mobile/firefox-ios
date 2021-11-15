// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import Client

class LibraryPanelViewStateTests: XCTestCase {
    var panelState: LibraryPanelViewState?

    override func setUp() {
        panelState = LibraryPanelViewState()
    }

    override func tearDown() {
        panelState = nil
    }

    //MARK: - Single panel interaction tests
    func testStateMachineInitializesWithProperState() {
        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .bookmarks(state: .mainView)

        XCTAssertEqual(actualState, expectedState, "The library panel view is not initializing correctly.")
    }

    func testStateChangingToSameState() {
        panelState?.currentState = .bookmarks(state: .mainView)

        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .bookmarks(state: .mainView)

        XCTAssertEqual(actualState, expectedState, "The library panel view changing from one state to the same state is not working!")
    }

    func testStateOnBookmarkPanelGoesIntoFolderState() {
        panelState?.currentState = .bookmarks(state: .inFolder)

        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .bookmarks(state: .inFolder)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .inFolder state for bookmarks")
    }

    func testStateOnBookmarkPanelGoesIntoEditFolderState() {
        panelState?.currentState = .bookmarks(state: .inFolder)
        panelState?.currentState = .bookmarks(state: .inFolderEditMode)

        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .bookmarks(state: .inFolderEditMode)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .inFolderEditMode state for bookmarks")
    }

    func testStateOnBookmarkPanelGoesIntoItemEditState() {
        panelState?.currentState = .bookmarks(state: .inFolder)
        panelState?.currentState = .bookmarks(state: .inFolderEditMode)
        panelState?.currentState = .bookmarks(state: .itemEditMode)

        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .bookmarks(state: .itemEditMode)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .inFolderEditMode state for bookmarks")
    }

    func testStateOnBookmarkPanelGoesBackToFolderEditModeFromItemEditState() {
        panelState?.currentState = .bookmarks(state: .inFolder)
        panelState?.currentState = .bookmarks(state: .inFolderEditMode)
        panelState?.currentState = .bookmarks(state: .itemEditMode)
        panelState?.currentState = .bookmarks(state: .inFolderEditMode)

        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .bookmarks(state: .inFolderEditMode)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .inFolderEditMode state for bookmarks from the .itemEditMode state")
    }

    func testStateOnBookmarkPanelFollowStateProgressionMovingIntoStates() {
        panelState?.currentState = .bookmarks(state: .inFolderEditMode)
        var actualState = panelState?.currentState
        var wrongState: LibraryPanelMainState = .bookmarks(state: .inFolderEditMode)
        let expectedState: LibraryPanelMainState = .bookmarks(state: .mainView)
        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .inFolderEditMode state for bookmarks")
        XCTAssertNotEqual(actualState, wrongState, "Attempting to move to the wrong state did not fail!")

        panelState?.currentState = .bookmarks(state: .itemEditMode)
        actualState = panelState?.currentState
        wrongState = .bookmarks(state: .itemEditMode)
        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .inFolderEditMode state for bookmarks")
        XCTAssertNotEqual(actualState, wrongState, "Attempting to move to the wrong state did not fail!")
    }

    func testStateOnBookmarkPanelFollowsStateProgressionMovingOutOfStates() {
        // Go to last state
        panelState?.currentState = .bookmarks(state: .inFolder)
        panelState?.currentState = .bookmarks(state: .inFolderEditMode)
        panelState?.currentState = .bookmarks(state: .itemEditMode)

        // attempt to climb backwards
        panelState?.currentState = .bookmarks(state: .inFolder)
        var actualState = panelState?.currentState
        var wrongState: LibraryPanelMainState = .bookmarks(state: .inFolder)
        let expectedState: LibraryPanelMainState = .bookmarks(state: .itemEditMode)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .inFolderEditMode state for bookmarks")
        XCTAssertNotEqual(actualState, wrongState, "Attempting to move to the wrong state did not fail!")

        panelState?.currentState = .bookmarks(state: .mainView)
        actualState = panelState?.currentState
        wrongState = .bookmarks(state: .mainView)
        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .inFolderEditMode state for bookmarks")
        XCTAssertNotEqual(actualState, wrongState, "Attempting to move to the wrong state did not fail!")
    }

    // MARK: - Multi-panel tests
    func testStateForBookmarkMainViewToOtherPanelMainView() {
        panelState?.currentState = .history(state: .mainView)

        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .history(state: .mainView)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly enter the .history(.mainView) state for the History Panel")
    }

    func testStateForBookmarkMainViewToOtherPanelMainViewAndBack() {
        panelState?.currentState = .history(state: .mainView)
        panelState?.currentState = .bookmarks(state: .mainView)

        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .bookmarks(state: .mainView)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly return to the .bookmarks(.mainView) state")
    }

    func testBookmarkViewInFolderModeSwitchingToOtherPanelAndReturningToCorrectBookmarksState() {
        panelState?.currentState = .bookmarks(state: .inFolder)
        panelState?.currentState = .history(state: .mainView)
        panelState?.currentState = .bookmarks(state: .mainView)

        let actualState = panelState?.currentState
        let expectedState: LibraryPanelMainState = .bookmarks(state: .inFolder)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly return to the .bookmarks(.inFolder) state")
    }

    func testChangingDifferentPanelsAndSavingStates() {
        panelState?.currentState = .bookmarks(state: .inFolder)
        panelState?.currentState = .bookmarks(state: .inFolderEditMode)
        panelState?.currentState = .history(state: .mainView)
        panelState?.currentState = .history(state: .inFolder)
        panelState?.currentState = .downloads
        panelState?.currentState = .bookmarks(state: .mainView)

        var actualState = panelState?.currentState
        var expectedState: LibraryPanelMainState = .bookmarks(state: .inFolderEditMode)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly return to the .bookmarks(.inFolderEditMode) state")

        panelState?.currentState = .history(state: .mainView)
        actualState = panelState?.currentState
        expectedState = .history(state: .inFolder)

        XCTAssertEqual(actualState, expectedState, "The library panel view did not correctly return to the .history(.inFolder) state")
    }
}

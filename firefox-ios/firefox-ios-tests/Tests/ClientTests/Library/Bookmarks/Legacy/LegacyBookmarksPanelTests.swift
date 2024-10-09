// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import Shared
import Common

@testable import Client

class LegacyBookmarksPanelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    // MARK: Bottom left action

    func testBottomLeftAction_ItemEditModeState_DoesNothing() throws {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        panel.bottomLeftButtonAction()

        XCTAssertNil(panel.viewControllerPresented)
    }

    func testBottomLeftAction_MainViewState_DoesNothing() throws {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .mainView))
        panel.bottomLeftButtonAction()

        XCTAssertNil(panel.viewControllerPresented)
    }

    func testBottomLeftAction_InFolderState_DoesNothing() throws {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        panel.bottomLeftButtonAction()

        XCTAssertNil(panel.viewControllerPresented)
    }

    func testBottomLeftAction_SearchState_DoesNothing() throws {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .search))
        panel.bottomLeftButtonAction()

        XCTAssertNil(panel.viewControllerPresented)
    }

    func testBottomLeftAction_InFolderEditModeState_BookmarkChangesState() {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        panel.bottomLeftButtonAction()

        guard let photonSheet = panel.viewControllerPresented as? PhotonActionSheet else {
            XCTFail("Should have shown a photon action sheet")
            return
        }

        // Fake clicking on new bookmark action
        let viewModel = photonSheet.viewModel.actions[0][0].items[0]
        _ = viewModel.tapHandler!(viewModel)

        XCTAssertEqual(panel.state, .bookmarks(state: .itemEditModeInvalidField))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
    }

    func testBottomLeftAction_InFolderEditModeState_FolderChangesState() {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        panel.bottomLeftButtonAction()

        guard let photonSheet = panel.viewControllerPresented as? PhotonActionSheet else {
            XCTFail("Should have shown a photon action sheet")
            return
        }

        // Fake clicking on new folder action
        let viewModel = photonSheet.viewModel.actions[0][1].items[0]
        _ = viewModel.tapHandler!(viewModel)

        XCTAssertEqual(panel.state, .bookmarks(state: .itemEditMode))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
    }

    func testBottomLeftAction_InFolderEditModeState_SeparatorDoesntChangeState() {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        panel.bottomLeftButtonAction()

        guard let photonSheet = panel.viewControllerPresented as? PhotonActionSheet else {
            XCTFail("Should have shown a photon action sheet")
            return
        }

        // Fake clicking on new separator action
        let viewModel = photonSheet.viewModel.actions[0][2].items[0]
        _ = viewModel.tapHandler!(viewModel)

        XCTAssertEqual(panel.state, .bookmarks(state: .inFolderEditMode))
        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 3, "Expected Edit button and flexibleSpace")
    }

    // MARK: Right top action

    func testBookmarks_InFolderEditMode_RightTopButton() {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        panel.handleRightTopButton()

        XCTAssertEqual(panel.state, .bookmarks(state: .inFolderEditMode), "No state change")
    }

    func testBookmarks_InFolder_RightTopButton() {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        panel.handleRightTopButton()

        XCTAssertEqual(panel.state, .bookmarks(state: .inFolder), "No state change")
    }

    func testBookmarks_MainView_RightTopButton() {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .mainView))
        panel.handleRightTopButton()

        XCTAssertEqual(panel.state, .bookmarks(state: .mainView), "No state change")
    }

    func testBookmarks_Search_RightTopButton() {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .search))
        panel.handleRightTopButton()

        XCTAssertEqual(panel.state, .bookmarks(state: .search), "No state change")
    }

    func testBookmarks_ItemEditMode_RightTopButton_NoBookmarkDetailPanel() {
        let panel = createPanel()
        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        panel.handleRightTopButton()

        XCTAssertEqual(
            panel.state,
            .bookmarks(state: .itemEditMode),
            "No state change on right top button click if we're not in a BookmarkDetailPanel")
    }

    func testBookmarks_ItemEditMode_RightTopButton_WithBookmarkDetailPanel() {
        let panel = createPanel()
        let mockNavigationController = SpyNavigationController(rootViewController: panel)
        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))

        // Pushing bookmark detail panel as if we are truly in .itemEditMode
        let bookmarkDetailPanel = LegacyBookmarkDetailPanel(profile: MockProfile(),
                                                            windowUUID: .XCTestDefaultUUID,
                                                            bookmarkNode: LocalDesktopFolder(),
                                                            parentBookmarkFolder: LocalDesktopFolder(),
                                                            deleteBookmark: nil)
        mockNavigationController.setViewControllers([panel, bookmarkDetailPanel], animated: false)

        panel.handleRightTopButton()
        XCTAssertEqual(panel.state, .bookmarks(state: .inFolderEditMode), "State changes")
    }

    func testBookmarks_ItemEditModeInvalidField_RightTopButton_WithBookmarkDetailPanel_NoStateChange() {
        let panel = createPanel()
        let mockNavigationController = SpyNavigationController(rootViewController: panel)
        panel.updatePanelState(newState: .bookmarks(state: .itemEditModeInvalidField))

        // Pushing bookmark detail panel as if we are truly in .itemEditMode
        let bookmarkDetailPanel = LegacyBookmarkDetailPanel(profile: MockProfile(),
                                                            windowUUID: .XCTestDefaultUUID,
                                                            withNewBookmarkNodeType: .bookmark,
                                                            parentBookmarkFolder: LocalDesktopFolder())
        mockNavigationController.setViewControllers([panel, bookmarkDetailPanel], animated: false)

        panel.handleRightTopButton()
        XCTAssertEqual(
            panel.state,
            .bookmarks(state: .itemEditModeInvalidField),
            "No state change when right top button is disabled"
        )
    }

    func testBookmarksButtons_MainFolder() {
        let panel = createPanel()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
        XCTAssertEqual(toolbarItems[1].title, "Edit")
    }

    func testBookmarksButtons_SubFolder() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
        XCTAssertEqual(toolbarItems[1].title, "Edit")
    }

    func testBookmarks_FolderEditMode() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        panel.enableEditMode()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 3, "Expected Add, Done button and flexibleSpace")
    }

    func testBookmarks_ItemEditMode() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        panel.presentInFolderActions()
        panel.handleItemEditMode()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 3, "Expected Edit button and flexibleSpace")
    }

    func testBookmarks_MainFolderLeavingEdit() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        panel.disableEditMode()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
    }

    func testBookmarksBack_ForInFolder() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        panel.handleLeftTopButton()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 2, "Expected Edit button and flexibleSpace")
    }

    func testBookmarksBack_ForItemEditMode() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        panel.handleLeftTopButton()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 3, "Expected Edit button and flexibleSpace")
    }

    func testBookmarksShouldDismissOnDone_ForMain() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .mainView))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testBookmarksShouldDismissOnDone_ForInFolder() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .inFolder))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testBookmarksShouldDismissOnDone_ForFolderEditMode() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .inFolderEditMode))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testBookmarksShouldDismissOnDone_ForItemEditMode() {
        let panel = createPanel()

        panel.updatePanelState(newState: .bookmarks(state: .itemEditMode))
        XCTAssertFalse(panel.shouldDismissOnDone())
    }
}

private extension LegacyBookmarksPanelTests {
    func createPanel() -> SpyBookmarksPanel {
        let profile = MockProfile()
        let viewModel = BookmarksPanelViewModel(profile: profile,
                                                bookmarksHandler: BookmarksHandlerMock(),
                                                bookmarkFolderGUID: "TestGuid")
        viewModel.bookmarkFolder = LocalDesktopFolder()
        return SpyBookmarksPanel(viewModel: viewModel, windowUUID: .XCTestDefaultUUID)
    }
}

class SpyBookmarksPanel: LegacyBookmarksPanel {
    // Spying on the present method to catch the presented view controller
    var viewControllerPresented: UIViewController?
    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        viewControllerPresented = viewControllerToPresent
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

class SpyNavigationController: UINavigationController {
    var pushedViewController: UIViewController?
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        pushedViewController = viewController
        super.pushViewController(viewController, animated: true)
    }
}

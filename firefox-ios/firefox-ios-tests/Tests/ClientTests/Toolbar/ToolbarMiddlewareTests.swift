// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common
import ToolbarKit

@testable import Client

final class ToolbarMiddlewareTests: XCTestCase, StoreTestUtility {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var mockStore: MockStoreForMiddleware<AppState>!
    var toolbarManager: ToolbarManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        toolbarManager = DefaultToolbarManager()

        // We must reset the global mock store prior to each test
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    // GeneralBrowserMiddlewareAction
    func testBrowserDidLoad_dispatchesDidLoadToolbars() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = GeneralBrowserMiddlewareAction(
            toolbarPosition: .top,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.browserDidLoad)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        let borderPosition = toolbarManager.getAddressBorderPosition(for: .top, isPrivate: false, scrollY: 0)
        let displayBorder = toolbarManager.shouldDisplayNavigationBorder(toolbarPosition: .top)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.didLoadToolbars)
        XCTAssertEqual(actionCalled.toolbarPosition, action.toolbarPosition)
        XCTAssertEqual(actionCalled.addressBorderPosition, borderPosition)
        XCTAssertEqual(actionCalled.displayNavBorder, displayBorder)
    }

    func testWebsiteDidScroll_dispatchesBorderPositionChanged() throws {
        let scrollOffset = CGPoint(x: 0, y: 100)
        let subject = createSubject(manager: toolbarManager)
        let action = GeneralBrowserMiddlewareAction(
            scrollOffset: scrollOffset,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.websiteDidScroll)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        let borderPosition = toolbarManager.getAddressBorderPosition(for: .top,
                                                                     isPrivate: false,
                                                                     scrollY: scrollOffset.y)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.borderPositionChanged)
        XCTAssertEqual(actionCalled.toolbarPosition, action.toolbarPosition)
        XCTAssertEqual(actionCalled.addressBorderPosition, borderPosition)
    }

    func testToolbarPositionChanged_dispatchesToolbarPositionChanged() throws {
        let scrollOffset = CGPoint(x: 0, y: 100)
        let subject = createSubject(manager: toolbarManager)
        let action = GeneralBrowserMiddlewareAction(
            scrollOffset: scrollOffset,
            toolbarPosition: .bottom,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.toolbarPositionChanged)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        let borderPosition = toolbarManager.getAddressBorderPosition(for: .bottom,
                                                                     isPrivate: false,
                                                                     scrollY: scrollOffset.y)
        let displayBorder = toolbarManager.shouldDisplayNavigationBorder(toolbarPosition: .bottom)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.toolbarPositionChanged)
        XCTAssertEqual(actionCalled.toolbarPosition, action.toolbarPosition)
        XCTAssertEqual(actionCalled.addressBorderPosition, borderPosition)
        XCTAssertEqual(actionCalled.displayNavBorder, displayBorder)
    }

    // MicrosurveyPromptMiddlewareAction
    // MicrosurveyPromptAction
    // ToolbarMiddlewareAction
    // ToolbarAction

    // MARK: - Helpers
    private func createSubject(manager: ToolbarManager) -> ToolbarMiddleware {
        return ToolbarMiddleware(manager: manager)
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: windowUUID
                        )
                    ),
                    .toolbar(
                        ToolbarState(
                            windowUUID: windowUUID
                        )
                    )
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}

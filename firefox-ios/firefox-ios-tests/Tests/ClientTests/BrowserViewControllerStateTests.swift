// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class BrowserViewControllerStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testAddNewTabAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigateTo)

        let action = getAction(for: .addNewTab)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .newTab)
    }

    func testShowNewTabLongpPressActions() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.displayView)

        let action = getAction(for: .showNewTabLongPressActions)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.displayView, .newTabLongPressActions)
    }

    func testClearDataAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.displayView)

        let action = getAction(for: .clearData)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.displayView, .dataClearance)
    }

    func testShowPasswordGeneratorAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()
        let URL = URL(string: "https://foo.com")!
        let webView = WKWebViewMock(URL)
        let frame = WKFrameInfoMock(webView: webView, frameURL: URL, isMainFrame: true)

        XCTAssertNil(initialState.displayView)

        let action = GeneralBrowserAction(frame: frame,
                                          windowUUID: .XCTestDefaultUUID,
                                          actionType: GeneralBrowserActionType.showPasswordGenerator)
        let newState = reducer(initialState, action)
        let displayView = newState.displayView!
        let desiredDisplayView =
        BrowserViewControllerState.DisplayType.passwordGenerator

        XCTAssertEqual(displayView, desiredDisplayView)
        XCTAssertNotNil(newState.frame)
    }

    func testReloadWebsiteAction() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigateTo)

        let action = getAction(for: .reloadWebsite)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigateTo, .reload)
    }

    // MARK: - Navigation Browser Action
    func test_tapOnCustomizeHomepage_navigationBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = getNavigationBrowserAction(for: .tapOnCustomizeHomepageButton, destination: .settings(.homePage))
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigationDestination?.destination, .settings(.homePage))
        XCTAssertEqual(newState.navigationDestination?.url, nil)
    }

    func test_tapOnCell_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = getNavigationBrowserAction(for: .tapOnCell, destination: .link, url: url)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigationDestination?.destination, .link)
        XCTAssertEqual(newState.navigationDestination?.url?.absoluteString, "www.example.com")
    }

    func test_tapOnLink_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = getNavigationBrowserAction(for: .tapOnLink, destination: .link, url: url)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigationDestination?.destination, .link)
        XCTAssertEqual(newState.navigationDestination?.url?.absoluteString, "www.example.com")
    }

    func test_tapOnShareSheet_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let shareSheetConfiguration = ShareSheetConfiguration(
            shareType: .site(url: url),
            shareMessage: nil,
            sourceView: UIView(),
            sourceRect: nil,
            toastContainer: UIView(),
            popoverArrowDirection: [.up]
        )
        let action = getNavigationBrowserAction(
            for: .tapOnShareSheet,
            destination: .shareSheet(shareSheetConfiguration)
        )
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigationDestination?.destination, .shareSheet(shareSheetConfiguration))
        XCTAssertEqual(newState.navigationDestination?.url, nil)
    }

    func test_longPressOnCell_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = getNavigationBrowserAction(for: .longPressOnCell, destination: .link, url: url)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigationDestination?.destination, .link)
        XCTAssertEqual(newState.navigationDestination?.url?.absoluteString, "www.example.com")
    }

    func test_tapOnOpenInNewTab_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.newTab, url: url, isPrivate: false, selectNewTab: false),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnOpenInNewTab
        )
        let newState = reducer(initialState, action)

        let navigationDestination = try XCTUnwrap(newState.navigationDestination)
        XCTAssertEqual(navigationDestination.destination, .newTab)
        XCTAssertEqual(navigationDestination.url?.absoluteString, "www.example.com")
        XCTAssertFalse(navigationDestination.isPrivate ?? true)
        XCTAssertFalse(navigationDestination.selectNewTab ?? true)
    }

    func test_tapOnOpenInNewTab_forPrivateTab_navigationBrowserAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.newTab, url: url, isPrivate: true, selectNewTab: true),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnOpenInNewTab
        )
        let newState = reducer(initialState, action)

        let navigationDestination = try XCTUnwrap(newState.navigationDestination)
        XCTAssertEqual(navigationDestination.destination, .newTab)
        XCTAssertEqual(navigationDestination.url?.absoluteString, "www.example.com")
        XCTAssertTrue(navigationDestination.isPrivate ?? false)
        XCTAssertTrue(navigationDestination.selectNewTab ?? false)
    }

    func test_tapOnSettingsSection_navigationBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = getNavigationBrowserAction(for: .tapOnSettingsSection, destination: .settings(.topSites))
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigationDestination?.destination, .settings(.topSites))
        XCTAssertEqual(newState.navigationDestination?.url, nil)
    }

    func test_shouldStartAtHome_withStartAtHomeAction_returnsTrue() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertFalse(initialState.shouldStartAtHome)

        let action = StartAtHomeAction(
            shouldStartAtHome: true,
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted
        )
        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.shouldStartAtHome)
    }

    func test_shouldStartAtHome_withStartAtHomeAction_returnsFalse() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertFalse(initialState.shouldStartAtHome)

        let action = StartAtHomeAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted
        )
        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.shouldStartAtHome)
    }

    // MARK: - Private
    private func createSubject() -> BrowserViewControllerState {
        return BrowserViewControllerState(windowUUID: .XCTestDefaultUUID)
    }

    private func browserViewControllerReducer() -> Reducer<BrowserViewControllerState> {
        return BrowserViewControllerState.reducer
    }

    private func getAction(for actionType: GeneralBrowserActionType) -> GeneralBrowserAction {
        return  GeneralBrowserAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func getNavigationBrowserAction(
        for actionType: NavigationBrowserActionType,
        destination: BrowserNavigationDestination,
        url: URL? = nil
    ) -> NavigationBrowserAction {
        return NavigationBrowserAction(
            navigationDestination: NavigationDestination(destination, url: url),
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }

    private func getPrivateModeAction(isPrivate: Bool, for actionType: PrivateModeActionType) -> PrivateModeAction {
        return  PrivateModeAction(isPrivate: isPrivate, windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    func getGeneralBrowserAction(selectedTabURL: URL? = nil,
                                 isNativeErrorPage: Bool? = nil,
                                 for actionType: GeneralBrowserActionType) -> GeneralBrowserAction {
        return  GeneralBrowserAction(selectedTabURL: selectedTabURL,
                                     isNativeErrorPage: isNativeErrorPage,
                                     windowUUID: .XCTestDefaultUUID,
                                     actionType: actionType)
    }
}

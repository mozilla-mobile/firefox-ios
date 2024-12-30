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
    func test_customizeHomepage_navigationBrowserAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = browserViewControllerReducer()

        XCTAssertNil(initialState.navigationDestination)

        let action = getNavigationBrowserAction(for: .tapOnCustomizeHomepage, destination: .customizeHomepage)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.navigationDestination?.destination, .customizeHomepage)
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

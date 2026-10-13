// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common
import ToolbarKit
@testable import Client

@MainActor
final class AddressToolbarContainerLensTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private let url = URL(string: "https://example.com")

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: MockTabManager())
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testInit_withoutToolbarState_returnsEmptyLeadingPageActions() {
        let appState = AppState(presentedComponents: PresentedComponentsState(components: []))
        let subject = AddressToolbarContainerLens(appState: appState, uuid: windowUUID)

        XCTAssertTrue(subject.leadingPageActions.isEmpty)
        XCTAssertTrue(subject.navigationActions.isEmpty)
    }

    // MARK: - navigationActions, derived straight from ToolbarState (no action involved)

    func testInit_showingNavigationToolbar_returnsEmptyNavigationActions() {
        let subject = createSubject(isShowingNavigationToolbar: true, canGoBack: true, canGoForward: true)

        XCTAssertTrue(subject.navigationActions.isEmpty)
    }

    func testInit_notShowingNavigationToolbar_returnsBackAndForwardActions() {
        let subject = createSubject(isShowingNavigationToolbar: false, canGoBack: true, canGoForward: false)

        XCTAssertEqual(subject.navigationActions.count, 2)
        XCTAssertEqual(subject.navigationActions[0].actionType, .back)
        XCTAssertEqual(subject.navigationActions[0].isEnabled, true)
        XCTAssertEqual(subject.navigationActions[1].actionType, .forward)
        XCTAssertEqual(subject.navigationActions[1].isEnabled, false)
    }

    func testInit_onRealWebsite_returnsShareAction() {
        let subject = createSubject(url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.actionType, .share)
    }

    // MARK: - trailingPageActions, derived straight from ToolbarState (no action involved)

    func testInit_withEmptySearch_returnsEmptyTrailingPageActions() {
        let subject = createSubject(isEmptySearch: true, url: url)

        XCTAssertTrue(subject.trailingPageActions.isEmpty)
    }

    func testInit_notLoading_returnsTrailingReloadAction() {
        let subject = createSubject(isEmptySearch: false, isLoading: false, url: url)

        XCTAssertEqual(subject.trailingPageActions.last?.actionType, .reload)
    }

    func testInit_loading_returnsTrailingStopLoadingAction() {
        let subject = createSubject(isEmptySearch: false, isLoading: true, url: url)

        XCTAssertEqual(subject.trailingPageActions.last?.actionType, .stopLoading)
    }

    // MARK: - hasAlternativeLocationColor, derived straight from ToolbarState (no action involved)

    func testInit_withTopPosition_noTopTabs_showingNavToolbar_disablesCustomColor() {
        let subject = createSubject(toolbarPosition: .top,
                                    isShowingTopTabs: false,
                                    isShowingNavigationToolbar: true,
                                    url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.hasCustomColor, false)
    }

    func testInit_withTopPosition_topTabsShown_enablesCustomColor() {
        let subject = createSubject(toolbarPosition: .top,
                                    isShowingTopTabs: true,
                                    isShowingNavigationToolbar: true,
                                    url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.hasCustomColor, true)
    }

    func testInit_withTopPosition_navToolbarHidden_enablesCustomColor() {
        let subject = createSubject(toolbarPosition: .top,
                                    isShowingTopTabs: false,
                                    isShowingNavigationToolbar: false,
                                    url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.hasCustomColor, true)
    }

    func testInit_withBottomPosition_enablesCustomColor() {
        let subject = createSubject(toolbarPosition: .bottom,
                                    isShowingTopTabs: false,
                                    isShowingNavigationToolbar: true,
                                    url: url)

        XCTAssertEqual(subject.leadingPageActions.first?.hasCustomColor, true)
    }

    // MARK: - Helpers

    private func createSubject(
        toolbarPosition: AddressToolbarPosition = .top,
        isShowingTopTabs: Bool = true,
        isShowingNavigationToolbar: Bool = true,
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        isEmptySearch: Bool = true,
        isLoading: Bool = false,
        url: URL? = nil
    ) -> AddressToolbarContainerLens {
        let addressToolbar = AddressBarState(windowUUID: windowUUID)
            .copy(url: url)
            .copy(isLoading: isLoading)
            .copy(isEmptySearch: isEmptySearch)

        let toolbarState = ToolbarState(windowUUID: windowUUID)
            .copy(toolbarPosition: toolbarPosition)
            .copy(addressToolbar: addressToolbar)
            .copy(isShowingNavigationToolbar: isShowingNavigationToolbar)
            .copy(isShowingTopTabs: isShowingTopTabs)
            .copy(canGoBack: canGoBack)
            .copy(canGoForward: canGoForward)

        let appState = AppState(presentedComponents: PresentedComponentsState(components: [.toolbar(toolbarState)]))
        return AddressToolbarContainerLens(appState: appState, uuid: windowUUID)
    }
}

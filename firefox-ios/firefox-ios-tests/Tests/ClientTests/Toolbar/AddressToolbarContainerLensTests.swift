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

    func testInit_withoutToolbarState_returnsEmptyLeadingPageActions() {
        let appState = AppState(presentedComponents: PresentedComponentsState(components: []))
        let lens = AddressToolbarContainerLens(appState: appState, uuid: windowUUID)

        XCTAssertTrue(lens.leadingPageActions.isEmpty)
    }

    func testInit_onRealWebsite_returnsShareAction() {
        let lens = subject(url: URL(string: "https://example.com"))

        XCTAssertEqual(lens.leadingPageActions.first?.actionType, .share)
    }

    // MARK: - hasAlternativeLocationColor, derived straight from ToolbarState (no action involved)

    func testInit_withTopPosition_noTopTabs_showingNavToolbar_disablesCustomColor() {
        let lens = subject(toolbarPosition: .top,
                           isShowingTopTabs: false,
                           isShowingNavigationToolbar: true,
                           url: URL(string: "https://example.com"))

        XCTAssertEqual(lens.leadingPageActions.first?.hasCustomColor, false)
    }

    func testInit_withTopPosition_topTabsShown_enablesCustomColor() {
        let lens = subject(toolbarPosition: .top,
                           isShowingTopTabs: true,
                           isShowingNavigationToolbar: true,
                           url: URL(string: "https://example.com"))

        XCTAssertEqual(lens.leadingPageActions.first?.hasCustomColor, true)
    }

    func testInit_withTopPosition_navToolbarHidden_enablesCustomColor() {
        let lens = subject(toolbarPosition: .top,
                           isShowingTopTabs: false,
                           isShowingNavigationToolbar: false,
                           url: URL(string: "https://example.com"))

        XCTAssertEqual(lens.leadingPageActions.first?.hasCustomColor, true)
    }

    func testInit_withBottomPosition_enablesCustomColor() {
        let lens = subject(toolbarPosition: .bottom,
                           isShowingTopTabs: false,
                           isShowingNavigationToolbar: true,
                           url: URL(string: "https://example.com"))

        XCTAssertEqual(lens.leadingPageActions.first?.hasCustomColor, true)
    }

    // MARK: - Helpers

    private func subject(
        toolbarPosition: AddressToolbarPosition = .top,
        isShowingTopTabs: Bool = true,
        isShowingNavigationToolbar: Bool = true,
        url: URL? = nil
    ) -> AddressToolbarContainerLens {
        let addressToolbar = AddressBarState(windowUUID: windowUUID).copy(url: url)
        let toolbarState = ToolbarState(windowUUID: windowUUID)
            .copy(toolbarPosition: toolbarPosition)
            .copy(addressToolbar: addressToolbar)
            .copy(isShowingNavigationToolbar: isShowingNavigationToolbar)
            .copy(isShowingTopTabs: isShowingTopTabs)
        let appState = AppState(presentedComponents: PresentedComponentsState(components: [.toolbar(toolbarState)]))
        return AddressToolbarContainerLens(appState: appState, uuid: windowUUID)
    }
}

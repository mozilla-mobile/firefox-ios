// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common

@testable import Client

final class NavigationActionsBuilderTests: XCTestCase {
    func testGetActions_whenShowingNavigationToolbar_returnsNoActions() {
        let actions = subject(isShowingNavigationToolbar: true, canGoBack: true, canGoForward: true)

        XCTAssertTrue(actions.isEmpty)
    }

    func testGetActions_whenNotShowingNavigationToolbar_returnsBackAndForward() {
        let actions = subject(isShowingNavigationToolbar: false, canGoBack: true, canGoForward: false)

        XCTAssertEqual(actions.count, 2)
        XCTAssertEqual(actions[0].actionType, .back)
        XCTAssertEqual(actions[0].isEnabled, true)
        XCTAssertEqual(actions[1].actionType, .forward)
        XCTAssertEqual(actions[1].isEnabled, false)
    }

    // MARK: - Helpers

    private func subject(
        isShowingNavigationToolbar: Bool,
        canGoBack: Bool,
        canGoForward: Bool
    ) -> [ToolbarActionConfiguration] {
        NavigationActionsBuilder.getActions(
            isShowingNavigationToolbar: isShowingNavigationToolbar,
            canGoBack: canGoBack,
            canGoForward: canGoForward
        )
    }
}

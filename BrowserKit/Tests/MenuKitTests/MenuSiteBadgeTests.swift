// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import MenuKit

@MainActor
final class MenuSiteBadgeTests: XCTestCase {
    var badge: MenuSiteBadge!

    override func setUp() async throws {
        try await super.setUp()
        badge = MenuSiteBadge(mainMenuHelper: MainMenuHelper())
    }

    override func tearDown() async throws {
        badge = nil
        try await super.tearDown()
    }

    func testTapHandlerCallback() {
        let expectation = XCTestExpectation(description: "Tap handler should be called")
        badge.tapHandler = { expectation.fulfill() }

        badge.tapHandler?()

        wait(for: [expectation], timeout: 1.0)
    }

    func testConfigure_setsVisibleLabelText() {
        badge.configure(text: "Protections", iconName: "", useTemplate: false)

        let label = firstLabel(in: badge)
        XCTAssertEqual(label?.text, "Protections")
    }

    func testConfigure_updatesLabelOnSubsequentCalls() {
        badge.configure(text: "Protections", iconName: "", useTemplate: false)
        badge.configure(text: "Ad Blocker", iconName: "", useTemplate: false)

        let label = firstLabel(in: badge)
        XCTAssertEqual(label?.text, "Ad Blocker")
    }

    private func firstLabel(in view: UIView) -> UILabel? {
        for subview in view.subviews {
            if let label = subview as? UILabel { return label }
            if let found = firstLabel(in: subview) { return found }
        }
        return nil
    }
}

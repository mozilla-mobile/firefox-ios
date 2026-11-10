// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import MenuKit

@MainActor
final class MenuSiteProtectionsHeaderTests: XCTestCase {
    var header: MenuSiteProtectionsHeader!

    override func setUp() async throws {
        try await super.setUp()
        header = MenuSiteProtectionsHeader()
    }

    override func tearDown() async throws {
        header = nil
        try await super.tearDown()
    }

    func testAdBlockerBadge_addedWhenDataProvided() {
        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: MenuSiteAdBlockerBadgeData(title: "Ad Blocker", image: "", shouldUseRenderMode: false)
        )

        XCTAssertEqual(visibleBadgeCount(), 2)
    }

    func testAdBlockerBadge_removedWhenNilData() {
        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: MenuSiteAdBlockerBadgeData(title: "Ad Blocker", image: "", shouldUseRenderMode: false)
        )

        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: nil
        )

        XCTAssertEqual(visibleBadgeCount(), 1)
    }

    func testPrivacyPanelBadge_addedWhenDataProvided() {
        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: MenuSiteAdBlockerBadgeData(title: "Ad Blocker", image: "", shouldUseRenderMode: false),
            privacyPanel: MenuSiteAdBlockerBadgeData(title: "Privacy", image: "", shouldUseRenderMode: false)
        )

        XCTAssertEqual(visibleBadgeCount(), 3)
    }

    func testPrivacyPanelBadge_removedWhenNilData() {
        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            privacyPanel: MenuSiteAdBlockerBadgeData(title: "Privacy", image: "", shouldUseRenderMode: false)
        )

        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            privacyPanel: nil
        )

        XCTAssertEqual(visibleBadgeCount(), 1)
    }

    func testBadges_wrapToNewRowWhenNotEnoughWidth() {
        header.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "Protections",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: MenuSiteAdBlockerBadgeData(title: "Ad Blocker", image: "", shouldUseRenderMode: false),
            privacyPanel: MenuSiteAdBlockerBadgeData(title: "Privacy", image: "", shouldUseRenderMode: false)
        )
        header.layoutIfNeeded()

        let rows = badgeRowStacks(in: header)
        XCTAssertGreaterThan(rows.count, 1)
        XCTAssertEqual(rows.flatMap(\.arrangedSubviews).count, 3)
    }

    // MARK: - Helpers

    private func visibleBadgeCount() -> Int {
        header.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        header.layoutIfNeeded()
        return badgeRowStacks(in: header).flatMap(\.arrangedSubviews).count
    }

    private func badgeRowStacks(in view: UIView) -> [UIStackView] {
        view.subviews.flatMap { subview -> [UIStackView] in
            if let stack = subview as? UIStackView,
               stack.arrangedSubviews.contains(where: { $0 is MenuSiteBadge }) {
                return [stack]
            }
            return badgeRowStacks(in: subview)
        }
    }
}

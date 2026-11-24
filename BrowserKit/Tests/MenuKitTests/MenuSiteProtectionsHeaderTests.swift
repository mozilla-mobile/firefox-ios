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
            adBlocker: MenuSiteBadgeData(title: "Ad Blocker", image: "", shouldUseRenderMode: false)
        )

        let badgesStack = firstStackView(in: header, axis: .horizontal)
        XCTAssertEqual(badgesStack?.arrangedSubviews.count, 2)
    }

    func testAdBlockerBadge_removedWhenNilData() {
        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: MenuSiteBadgeData(title: "Ad Blocker", image: "", shouldUseRenderMode: false)
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

        let badgesStack = firstStackView(in: header, axis: .horizontal)
        XCTAssertEqual(badgesStack?.arrangedSubviews.count, 1)
    }

    func testVPNBadge_addedWhenDataProvided() {
        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            vpn: MenuSiteBadgeData(title: "VPN", image: "", shouldUseRenderMode: false)
        )

        let badgesStack = firstStackView(in: header, axis: .horizontal)
        XCTAssertEqual(badgesStack?.arrangedSubviews.count, 2)
    }

    func testBadges_orderedProtectionsAdBlockerVPN() {
        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "Protections",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: MenuSiteBadgeData(title: "Ad Blocker", image: "", shouldUseRenderMode: false),
            vpn: MenuSiteBadgeData(title: "VPN", image: "", shouldUseRenderMode: false)
        )

        let badgesStack = firstStackView(in: header, axis: .horizontal)
        let titles = badgesStack?.arrangedSubviews.map { badgeTitle(in: $0) }
        XCTAssertEqual(titles, ["Protections", "Ad Blocker", "VPN"])
    }

    // MARK: - Helpers

    private func badgeTitle(in view: UIView) -> String? {
        if let label = view as? UILabel { return label.text }
        for subview in view.subviews {
            if let title = badgeTitle(in: subview) { return title }
        }
        return nil
    }

    private func firstStackView(in view: UIView, axis: NSLayoutConstraint.Axis) -> UIStackView? {
        for subview in view.subviews {
            if let stack = subview as? UIStackView,
               stack.arrangedSubviews.contains(where: { $0 is MenuSiteBadge }) {
                return stack
            }
            if let found = firstStackView(in: subview, axis: axis) { return found }
        }
        return nil
    }
}

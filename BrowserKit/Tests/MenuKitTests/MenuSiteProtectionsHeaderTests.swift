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

        let badgesStack = firstStackView(in: header, axis: .horizontal)
        XCTAssertEqual(badgesStack?.arrangedSubviews.count, 1)
    }

    func testBadgesRow_longTranslationsStackVerticallyWithoutWrapping() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 300))
        header.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(header)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            header.topAnchor.constraint(equalTo: container.topAnchor)
        ])

        header.setupDetails(
            title: "tagesschau.de",
            subtitle: "tagesschau.de",
            image: nil,
            state: "Schutzmaßnahmen",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: MenuSiteAdBlockerBadgeData(title: "Werbeblocker", image: "", shouldUseRenderMode: false)
        )
        container.layoutIfNeeded()

        guard let badgesStack = firstStackView(in: header, axis: .vertical) else {
            XCTFail("Badges stack not found")
            return
        }
        XCTAssertEqual(badgesStack.axis, .vertical)
    }

    func testBadgesRow_shortTitlesStayHorizontal() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 300))
        header.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(header)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            header.topAnchor.constraint(equalTo: container.topAnchor)
        ])

        header.setupDetails(
            title: "example.com",
            subtitle: "Connection is secure",
            image: nil,
            state: "On",
            stateImage: "",
            shouldUseRenderMode: false,
            adBlocker: MenuSiteAdBlockerBadgeData(title: "Ad Blocker", image: "", shouldUseRenderMode: false)
        )
        container.layoutIfNeeded()

        guard let badgesStack = firstStackView(in: header, axis: .horizontal) else {
            XCTFail("Badges stack not found")
            return
        }
        XCTAssertEqual(badgesStack.axis, .horizontal)
    }

    // MARK: - Helpers

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

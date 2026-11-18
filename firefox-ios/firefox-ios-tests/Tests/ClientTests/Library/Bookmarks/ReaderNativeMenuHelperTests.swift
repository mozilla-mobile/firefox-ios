// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import XCTest

@testable import Client

@MainActor
final class ReaderNativeMenuHelperTests: XCTestCase {
    func test_menu_forReadingListItem_returnsExpectedActions() {
        let subject = createSubject()
        let site = Site.createBasicSite(url: "https://www.mozilla.org", title: "Mozilla")

        let menu = subject.menu(for: site, sourceView: UIView(), onRemove: {})

        XCTAssertEqual(titles(of: menu), [
            .OpenInNewTabContextMenuTitle,
            .OpenInNewPrivateTabContextMenuTitle,
            .RemoveContextMenuTitle,
            .ShareContextMenuTitle
        ])
    }

    func test_menu_forItemWithInvalidURL_returnsNil() {
        let subject = createSubject()
        let site = Site.createBasicSite(url: "", title: "Empty")

        XCTAssertNil(subject.menu(for: site, sourceView: UIView(), onRemove: {}))
    }

    func test_menu_forRemoveAction_isDestructive() throws {
        let subject = createSubject()
        let site = Site.createBasicSite(url: "https://www.mozilla.org", title: "Mozilla")

        let menu = try XCTUnwrap(subject.menu(for: site, sourceView: UIView(), onRemove: {}))
        let remove = try XCTUnwrap(
            menu.children.compactMap { $0 as? UIAction }.first { $0.title == .RemoveContextMenuTitle }
        )

        XCTAssertTrue(remove.attributes.contains(.destructive))
    }

    private func createSubject() -> ReaderNativeMenuHelper {
        let subject = ReaderNativeMenuHelper(libraryPanelDelegate: nil, navigationHandler: nil)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func titles(of menu: UIMenu?) -> [String] {
        menu?.children.map(\.title) ?? []
    }
}

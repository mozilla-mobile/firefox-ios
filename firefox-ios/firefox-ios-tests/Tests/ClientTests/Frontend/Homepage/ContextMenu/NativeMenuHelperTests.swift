// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import XCTest

@testable import Client

@MainActor
final class NativeMenuHelperTests: XCTestCase {
    func test_menu_forRegularTopSite_returnsExpectedActions() {
        let subject = createSubject()
        let site = Site.createBasicSite(url: "https://www.mozilla.org", title: "Mozilla")

        let menu = subject.menu(for: topSiteItem(site), sourceView: nil)

        XCTAssertEqual(titles(of: menu), [
            .PinTopsiteActionTitle2,
            .OpenInNewTabContextMenuTitle,
            .OpenInNewPrivateTabContextMenuTitle,
            .RemoveContextMenuTitle,
            .ShareContextMenuTitle
        ])
    }

    func test_menu_forPinnedTopSite_returnsExpectedActions() throws {
        let subject = createSubject()
        let site = try XCTUnwrap(MockTopSiteHistoryManager.defaultSuccessData.first)

        let menu = subject.menu(for: topSiteItem(site), sourceView: nil)

        XCTAssertEqual(titles(of: menu), [
            .UnpinTopsiteActionTitle2,
            .OpenInNewTabContextMenuTitle,
            .OpenInNewPrivateTabContextMenuTitle,
            .RemoveContextMenuTitle,
            .ShareContextMenuTitle
        ])
    }

    func test_menu_forSponsoredTopSite_returnsExpectedActions() {
        let subject = createSubject()
        let site = MockSponsoredTileData.makeSponsoredSite(
            url: "https://www.mozilla.org",
            title: "Mozilla",
            clickURL: "https://www.mozilla.org/click",
            impressionURL: "https://www.mozilla.org/impression",
            imageURL: "https://www.mozilla.org/image.jpg"
        )

        let menu = subject.menu(for: topSiteItem(site), sourceView: nil)

        XCTAssertEqual(titles(of: menu), [
            .OpenInNewTabContextMenuTitle,
            .OpenInNewPrivateTabContextMenuTitle,
            .FirefoxHomepage.ContextualMenu.Settings,
            .FirefoxHomepage.ContextualMenu.SponsoredContent,
            .ShareContextMenuTitle
        ])
    }

    func test_menu_forTopSiteWithInvalidURL_returnsNil() {
        let subject = createSubject()
        let site = Site.createBasicSite(url: "", title: "Empty")

        XCTAssertNil(subject.menu(for: topSiteItem(site), sourceView: nil))
    }

    func test_menu_forRemoveAction_isDestructive() throws {
        let subject = createSubject()
        let site = Site.createBasicSite(url: "https://www.mozilla.org", title: "Mozilla")

        let menu = try XCTUnwrap(subject.menu(for: topSiteItem(site), sourceView: nil))
        let remove = try XCTUnwrap(
            menu.children.compactMap { $0 as? UIAction }.first { $0.title == .RemoveContextMenuTitle }
        )

        XCTAssertTrue(remove.attributes.contains(.destructive))
    }

    func test_menu_forNonTopSiteItem_returnsNil() {
        let subject = createSubject()

        XCTAssertNil(subject.menu(for: .searchBar, sourceView: nil))
        XCTAssertNil(subject.menu(for: .addShortcutTile(nil), sourceView: nil))
    }

    private func createSubject() -> NativeMenuHelper {
        let subject = NativeMenuHelper(windowUUID: .XCTestDefaultUUID, toastContainer: UIView())
        trackForMemoryLeaks(subject)
        return subject
    }

    private func topSiteItem(_ site: Site) -> HomepageItem {
        .topSite(TopSiteConfiguration(site: site), nil)
    }

    private func titles(of menu: UIMenu?) -> [String] {
        menu?.children.map(\.title) ?? []
    }
}

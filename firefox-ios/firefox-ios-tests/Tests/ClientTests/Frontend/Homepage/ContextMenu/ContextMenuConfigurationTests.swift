// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage
import XCTest

@testable import Client

@MainActor
final class ContextMenuConfigurationTests: XCTestCase {
    func tests_initialState_forMerinoItem_returnsExpectedState() {
        let merinoItem: HomepageItem = .merino(
            MerinoStoryConfiguration(
                story: MerinoStory(
                    corpusItemId: "",
                    scheduledCorpusItemId: "",
                    url: URL("www.example.com/1234")!,
                    title: "Site 0",
                    excerpt: "example description",
                    topic: nil,
                    publisher: "",
                    isTimeSensitive: false,
                    imageURL: URL("www.example.com/image")!,
                    iconURL: nil,
                    tileId: 0,
                    receivedRank: 0
                )
            )
        )
        guard case let .merino(state) = merinoItem else { return }
        let subject = ContextMenuConfiguration(
            site: Site.createBasicSite(url: state.url?.absoluteString ?? "", title: state.title),
            menuType: MenuType(homepageItem: merinoItem),
            toastContainer: UIView()
        )
        XCTAssertEqual(subject.site?.tileURL.absoluteString, "file:///www.example.com/1234")
        XCTAssertEqual(subject.site?.title, "Site 0")
    }

    func tests_initialState_forTopSitesItem_returnsExpectedState() {
        let topSiteItem: HomepageItem = .topSite(
            TopSiteConfiguration(
                site: Site.createBasicSite(url: "www.example.com/1234", title: "Site 0")
            ), nil
        )
        guard case let .topSite(state, nil) = topSiteItem else { return }
        let subject = ContextMenuConfiguration(
            site: state.site,
            menuType: MenuType(homepageItem: topSiteItem),
            toastContainer: UIView()
        )
        XCTAssertEqual(subject.site?.tileURL.absoluteString, "www.example.com/1234")
        XCTAssertEqual(subject.site?.title, "Site 0")
    }
}

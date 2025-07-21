// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Storage
import XCTest

@testable import Client

final class ContextMenuConfigurationTests: XCTestCase {
    func tests_initialState_forPocketItem_returnsExpectedState() {
        let pocketItem: HomepageItem = .merino(
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
        let subject = ContextMenuConfiguration(
            homepageSection: .pocket(nil),
            item: pocketItem,
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
        let subject = ContextMenuConfiguration(
            homepageSection: .topSites(nil, 4),
            item: topSiteItem,
            toastContainer: UIView()
        )
        XCTAssertEqual(subject.site?.tileURL.absoluteString, "www.example.com/1234")
        XCTAssertEqual(subject.site?.title, "Site 0")
    }

    func tests_initialState_forNoItem_returnsExpectedState() {
        let subject = ContextMenuConfiguration(
            homepageSection: .topSites(nil, 4),
            item: nil,
            toastContainer: UIView()
        )
        XCTAssertNil(subject.site)
    }
}

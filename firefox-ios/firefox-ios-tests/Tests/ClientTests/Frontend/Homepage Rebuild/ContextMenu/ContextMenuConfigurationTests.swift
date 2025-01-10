// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import XCTest

@testable import Client

final class ContextMenuConfigurationTests: XCTestCase {
    func tests_initialState_forPocketItem_returnsExpectedState() {
        let pocketItem: HomepageItem = .pocket(
            PocketStoryState(
                story: PocketStory(
                        url: URL("www.example.com/1234")!,
                        title: "Site 0",
                        domain: "www.example.com",
                        timeToRead: nil,
                        storyDescription: "example description",
                        imageURL: URL("www.example.com/image")!,
                        id: 0,
                        flightId: nil,
                        campaignId: nil,
                        priority: nil,
                        context: nil,
                        rawImageSrc: nil,
                        shim: nil,
                        caps: nil,
                        sponsor: nil)
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

    func tests_initialState_forPocketDiscoverItem_returnsExpectedState() {
        let pocketItem: HomepageItem = .pocketDiscover(
            PocketDiscoverState(
                title: "Discover Site 0",
                url: URL("www.example.com/1234")
            )
        )
        let subject = ContextMenuConfiguration(
            homepageSection: .pocket(nil),
            item: pocketItem,
            toastContainer: UIView()
        )
        XCTAssertEqual(subject.site?.tileURL.absoluteString, "file:///www.example.com/1234")
        XCTAssertEqual(subject.site?.title, "Discover Site 0")
    }

    func tests_initialState_forTopSitesItem_returnsExpectedState() {
        let topSiteItem: HomepageItem = .topSite(
            TopSiteState(
                site: Site.createBasicSite(url: "www.example.com/1234", title: "Site 0")
            ), nil
        )
        let subject = ContextMenuConfiguration(
            homepageSection: .topSites(4),
            item: topSiteItem,
            toastContainer: UIView()
        )
        XCTAssertEqual(subject.site?.tileURL.absoluteString, "www.example.com/1234")
        XCTAssertEqual(subject.site?.title, "Site 0")
    }

    func tests_initialState_forNoItem_returnsExpectedState() {
        let subject = ContextMenuConfiguration(
            homepageSection: .topSites(4),
            item: nil,
            toastContainer: UIView()
        )
        XCTAssertNil(subject.site)
    }
}

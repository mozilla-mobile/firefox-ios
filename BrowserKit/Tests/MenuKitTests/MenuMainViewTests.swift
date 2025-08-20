// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import MenuKit

final class MenuMainViewTests: XCTestCase {
    var menuView: MenuMainView!

    override func setUp() {
        super.setUp()
        menuView = MenuMainView()
        menuView.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
    }

    override func tearDown() {
        menuView = nil
        super.tearDown()
    }

    func testShouldNotDisplayBanner_onSiteMenu() {
        setupDetails(isBannerFlagEnabled: true, isBrowserDefault: false, bannerShown: false)

        let homepageSection = MenuSection(isExpanded: false, isHomepage: false, options: [])
        menuView.reloadDataView(with: [homepageSection])

        XCTAssertFalse(menuView.subviews.contains(where: { $0 is HeaderBanner }))
    }

    func testShouldNotDisplayBanner_ifBrowserIsDefault() {
        setupDetails(isBannerFlagEnabled: true, isBrowserDefault: true, bannerShown: false)

        let homepageSection = MenuSection(isExpanded: false, isHomepage: true, options: [])
        menuView.reloadDataView(with: [homepageSection])

        XCTAssertFalse(menuView.subviews.contains(where: { $0 is HeaderBanner }))
    }

    func testShouldNotDisplayBanner_ifWasShown() {
        setupDetails(isBannerFlagEnabled: true, isBrowserDefault: false, bannerShown: true)

        let homepageSection = MenuSection(isExpanded: false, isHomepage: true, options: [])
        menuView.reloadDataView(with: [homepageSection])

        XCTAssertFalse(menuView.subviews.contains(where: { $0 is HeaderBanner }))
    }

    func testShouldDisplayBanner() {
        setupDetails(isBannerFlagEnabled: true, isBrowserDefault: false, bannerShown: false)

        let homepageSection = MenuSection(isExpanded: false, isHomepage: true, options: [])
        menuView.reloadDataView(with: [homepageSection])

        XCTAssertTrue(menuView.subviews.contains(where: { $0 is HeaderBanner }))
    }

    func testCloseBannerCallback() {
        let homepageSection = MenuSection(isExpanded: false, isHomepage: true, options: [])
        setupDetails(isBannerFlagEnabled: true, isBrowserDefault: false, bannerShown: false)
        menuView.reloadDataView(with: [homepageSection])

        let expectation = XCTestExpectation(description: "Close banner callback should be called")
        menuView.closeBannerButtonCallback = {
            expectation.fulfill()
        }

        menuView.headerBanner.closeButtonCallback?()

        wait(for: [expectation], timeout: 1.0)
    }

    func testHeightCalculation_forExpandedSection() {
        let expandedSection = MenuSection(isExpanded: true, isHomepage: false, options: [])
        let expectation = XCTestExpectation(description: "Height should be calculated")

        menuView.onCalculatedHeight = { height in
            XCTAssertGreaterThan(height, 0)
            expectation.fulfill()
        }

        menuView.reloadDataView(with: [expandedSection])
        menuView.layoutIfNeeded()

        wait(for: [expectation], timeout: 1.0)
    }

    func testBannerButtonCallbackCalled() {
        let expectation = XCTestExpectation(description: "Banner button callback")
        setupDetails(isBannerFlagEnabled: true, isBrowserDefault: false, bannerShown: false)

        menuView.bannerButtonCallback = {
            expectation.fulfill()
        }

        menuView.reloadDataView(with: [MenuSection(isExpanded: false, isHomepage: true, options: [])])
        menuView.headerBanner.bannerButtonCallback?()

        wait(for: [expectation], timeout: 1.0)
    }

    private func setupDetails(isBannerFlagEnabled: Bool, isBrowserDefault: Bool, bannerShown: Bool) {
        menuView.setupDetails(
            title: "",
            subtitle: "",
            image: nil,
            isBannerFlagEnabled: isBannerFlagEnabled,
            isBrowserDefault: isBrowserDefault,
            bannerShown: bannerShown
        )
    }
}

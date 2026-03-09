// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest

@MainActor
final class HomePageScreen {
    private let app: XCUIApplication
    private let sel: HomePageSelectorsSet
    private let topSitesSel: TopSitesSelectorsSet

    private var collection: XCUIElement { sel.COLLECTION_VIEW.element(in: app) }
    private var tabsButton: XCUIElement { sel.TABS_BUTTON.element(in: app) }
    private var homeLogo: XCUIElement { sel.HOME_LOGO.element(in: app) }
    private var privHomepageTitle: XCUIElement { sel.PRIVATE_HOME_TITLE.element(in: app) }

    init(
        app: XCUIApplication,
        selectors: HomePageSelectorsSet = HomePageSelectors(),
        topSitesSelectors: TopSitesSelectorsSet = TopSitesSelectors()
    ) {
        self.app = app
        self.sel = selectors
        self.topSitesSel = topSitesSelectors
    }

    func swipeToCustomizeHomeOption() {
        if UIDevice.current.userInterfaceIdiom != .pad {
            BaseTestCase().mozWaitForElementToExist(collection)
            collection.swipeUp()
            collection.swipeUp()
        }
    }

    func assertTabsButtonExists() {
        BaseTestCase().mozWaitForElementToExist(tabsButton)
    }

    func waitUntilTabsButtonHittable(timeout: TimeInterval = 2.0) {
        BaseTestCase().mozWaitElementHittable(element: tabsButton, timeout: timeout)
    }

    func assertHomeLogoExists() {
        BaseTestCase().mozWaitForElementToExist(homeLogo)
    }

    func assertPrivateHomeTitleExists() {
        BaseTestCase().mozWaitForElementToExist(privHomepageTitle)
    }

    func validateHomeLogoPosition(isPrivate: Bool = false) {
        if !isPrivate {
            XCTAssertTrue(homeLogo.isAbove(
                element: topSitesSel.TOP_SITE_ITEM_CELL.element(in: app).firstMatch),
                          "Firefox Home logo should be above the top sites section")
        } else {
            XCTAssertTrue(homeLogo.isAbove(
                element: privHomepageTitle),
                          "Firefox Home logo should be above the home page title in private mode")
        }
    }

    func validateHomePageLogo(isPrivate: Bool) {
        assertHomeLogoExists()
        validateHomeLogoPosition(isPrivate: isPrivate)
    }
}

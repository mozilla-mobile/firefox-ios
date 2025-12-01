// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class SSLWarningScreen {
    private let app: XCUIApplication
    private let sel: SSLWarningSelectorsSet

    init(app: XCUIApplication, selectors: SSLWarningSelectorsSet = SSLWarningSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func waitForWarning() {
        let warning = sel.WARNING_MESSAGE.element(in: app)
        BaseTestCase().mozWaitForElementToExist(warning)
    }

    func assertWarningVisible() {
        let warning = sel.WARNING_MESSAGE.element(in: app)
        XCTAssertTrue(warning.exists, "Expected SSL warning to be visible")
    }

    func tapGoBack() {
        sel.GO_BACK_BUTTON.element(in: app).waitAndTap()
    }

    func waitForWarningToDisappear() {
        let warning = sel.WARNING_MESSAGE.element(in: app)
        BaseTestCase().mozWaitForElementToNotExist(warning)
    }

    func tapAdvanced() {
        sel.ADVANCED_BUTTON.element(in: app).waitAndTap()
    }

    func tapVisitSiteAnyway() {
        sel.VISIT_SITE_ANYWAY_LINK.element(in: app).waitAndTap()
    }

    func waitForPageToLoadAfterBypass() {
        let domain = sel.PAGE_DOMAIN.element(in: app)
        BaseTestCase().mozWaitForElementToExist(domain, timeout: TIMEOUT_LONG)
    }
}

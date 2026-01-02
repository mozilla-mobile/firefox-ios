// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@MainActor
final class SaveLoginAlertScreen {
    private let app: XCUIApplication
    private let sel: SaveLoginAlertSelectorsSet

    init(app: XCUIApplication, selectors: SaveLoginAlertSelectorsSet = SaveLoginAlertSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func waitForAlert() {
        BaseTestCase().waitForElementsToExist([
            sel.ALERT_TITLE.element(in: app),
            sel.DONT_UPDATE_BUTTON.element(in: app),
            sel.UPDATE_BUTTON.element(in: app)
        ])
    }

    func respondToAlert(savePassword: Bool) {
        if savePassword {
            sel.UPDATE_BUTTON.element(in: app).waitAndTap()
        } else {
            sel.DONT_UPDATE_BUTTON.element(in: app).waitAndTap()
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class TranslationSnackBarTest: BaseTestCase {
    func testSnackBar() {
        userState.localeIsExpectedDifferent = true
        navigator.openURL(path(forTestPage: "manifesto-zh-CN.html"))
        waitUntilPageLoad()
        navigator.goto(TranslatePageMenu)
        waitForExistence(app.buttons["TranslationPrompt.doTranslate"])
    }

    func testSetting() {
        navigator.goto(TranslationSettings)
    }
}

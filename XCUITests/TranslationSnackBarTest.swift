/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let spanishURL = "elpais.es"

class TranslationSnackBarTest: BaseTestCase {

    // This test checks to the correct functionalty of the Translation prompt and Translation is done corrrectly using Google
    func testSnackBarDisplayed() {
        userState.localeIsExpectedDifferent = true
        // Disable local site due to snackbar not accessible there
        // navigator.openURL(path(forTestPage: "manifesto-zh-CN.html"))
        navigator.openURL(spanishURL)
        waitUntilPageLoad()
        waitForExistence(app.buttons["TranslationPrompt.doTranslate"], timeout: 5)
        navigator.performAction(Action.SelectDontTranslateThisPage)
        XCTAssertFalse(app.buttons["TranslationPrompt.dontTranslate"].exists)
        navigator.performAction(Action.ReloadURL)
        waitForExistence(app.buttons["TranslationPrompt.doTranslate"], timeout: 5)
        navigator.performAction(Action.SelectTranslateThisPage)
        waitForValueContains(app.textFields["url"], value: "translate.google")
    }
    
    // This test checks to see if Translation is enabled by default from the Settings menu and can be correctly disabled
    func testTranslationDisabled() {
        navigator.goto(TranslationSettings)
        let translationSwitch = app.switches["TranslateSwitchValue"]
        XCTAssertTrue(translationSwitch.isEnabled)
        navigator.performAction(Action.DisableTranslation)
        // Disable local site due to snackbar not accessible there
        // navigator.openURL(path(forTestPage: "manifesto-zh-CN.html"))
        navigator.openURL(spanishURL)
        waitUntilPageLoad()
        XCTAssertFalse(app.buttons["TranslationPrompt.dontTranslate"].exists)
    }
    
    // This test checks to see if Translation is correctly done when using Bing
    func testTranslateBing() {
        userState.localeIsExpectedDifferent = true
        navigator.goto(TranslationSettings)
        navigator.performAction(Action.SelectBing)
        // Disable local site due to snackbar not accessible there
        // navigator.openURL(path(forTestPage: "manifesto-zh-CN.html"))
        navigator.openURL(spanishURL)
        waitUntilPageLoad()
        navigator.performAction(Action.SelectTranslateThisPage)
        // Disable check after iOS 13.3 update #5937
        // Value on url text field is not updated
        // waitForValueContains(app.textFields["url"], value: "translatetheweb")
    }
}

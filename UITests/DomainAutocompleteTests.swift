/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class DomainAutocompleteTests: KIFTestCase {
    override func setUp() {
        super.setUp()
        BrowserUtils.dismissFirstRunUI(tester())
    }
    
    func testAutocomplete() {
        BrowserUtils.addHistoryEntry("Foo bar baz", url: URL(string: "https://foo.bar.baz.org/dingbat")!)

        tester().tapView(withAccessibilityIdentifier: "url")
        let textField = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField

        // Multiple subdomains.
        tester().enterText(intoCurrentFirstResponder: "f")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "f", completion: "oo.bar.baz.org/")
        tester().clearTextFromFirstResponder()
        tester().enterText(intoCurrentFirstResponder: "b")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "b", completion: "ar.baz.org/")
        tester().enterText(intoCurrentFirstResponder: "a")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "ba", completion: "r.baz.org/")
        tester().enterText(intoCurrentFirstResponder: "z")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "baz", completion: ".org/")
    }

    override func tearDown() {
        super.tearDown()
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Cancel")
            tester().tapView(withAccessibilityLabel: "Cancel")
        } catch _ {
        }
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}

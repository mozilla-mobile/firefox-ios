/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import EarlGrey

class DomainAutocompleteTests: KIFTestCase {
    override func setUp() {

        super.setUp()
        BrowserUtils.configEarlGrey()
        BrowserUtils.dismissFirstRunUI()
    }

    func testAutocomplete() {
        BrowserUtils.addHistoryEntry("Foo bar baz", url: URL(string: "https://foo.bar.baz.org/dingbat")!)

        tester().tapView(withAccessibilityIdentifier: "url")
        let textField = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField

        // Multiple subdomains.
        tester().enterText(intoCurrentFirstResponder: "f")
        tester().waitForAnimationsToFinish()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "f", completion: "oo.bar.baz.org")
        tester().clearTextFromFirstResponder()
        tester().waitForAnimationsToFinish()
        // Expected behavior but changed intentionally https://bugzilla.mozilla.org/show_bug.cgi?id=1536746
        // tester().enterText(intoCurrentFirstResponder: "b")
        // BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "b", completion: "ar.baz.org")
        // tester().enterText(intoCurrentFirstResponder: "a")
        // BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "ba", completion: "r.baz.org")
        // tester().enterText(intoCurrentFirstResponder: "z")

        // Current and temporary behaviour entering more than 2 chars for the matching
        tester().enterText(intoCurrentFirstResponder: "bar")
        tester().waitForAnimationsToFinish()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "bar", completion: ".baz.org")
        tester().enterText(intoCurrentFirstResponder: ".ba")
        tester().waitForAnimationsToFinish()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "bar.ba", completion: "z.org")
        tester().enterText(intoCurrentFirstResponder: "z")
        tester().waitForAnimationsToFinish()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "bar.baz", completion: ".org")
    }

    func testAutocompleteAfterDeleteWithBackSpace() {
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityIdentifier: "url")
        let textField = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField
        tester().enterText(intoCurrentFirstResponder: "facebook")
        tester().waitForAnimationsToFinish()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "facebook", completion: ".com")

        // Remove the completion part .com
        tester().enterText(intoCurrentFirstResponder: XCUIKeyboardKey.delete.rawValue)
        tester().waitForAnimationsToFinish()

        // Tap on Go to perform a search
        EarlGrey.selectElement(with: grey_accessibilityLabel("Go")).perform(grey_tap())
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 1)

        // Tap on the url to go back to the awesomebar results
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().waitForAnimationsToFinish()
        let textField2 = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField
        // Facebook word appears highlighted and so it is shown as facebook\u{7F} when extracting the value to compare
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField2 , prefix: "", completion: "facebook\u{7F}")
    }

    // Bug https://bugzilla.mozilla.org/show_bug.cgi?id=1541832 scenario 1
    func testAutocompleteOnechar() {
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityIdentifier: "url")
        let textField = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField
        tester().enterText(intoCurrentFirstResponder: "f")
        tester().waitForAnimationsToFinish()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "f", completion: "acebook.com")
    }

    // Bug https://bugzilla.mozilla.org/show_bug.cgi?id=1541832 scenario 2
    func testAutocompleteOneCharAfterRemovingPreviousTerm() {
        tester().tapView(withAccessibilityIdentifier: "url")
        let textField = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField
        tester().enterText(intoCurrentFirstResponder: "foo")

        // Remove the completion part and the the foo chars one by one
        for _ in 1...4 {
            EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_typeText("\u{0008}"))
        }
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "f")
        tester().waitForAnimationsToFinish()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "f", completion: "acebook.com")
    }

    // Bug https://bugzilla.mozilla.org/show_bug.cgi?id=1541832 scenario 3
    func testAutocompleteOneCharAfterRemovingWithClearButton() {
        tester().tapView(withAccessibilityIdentifier: "url")
        let textField = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField
        tester().enterText(intoCurrentFirstResponder: "foo")
        tester().tapView(withAccessibilityLabel: "Clear text")
        tester().enterText(intoCurrentFirstResponder: "f")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "f", completion: "acebook.com")
    }

    override func tearDown() {
        super.tearDown()
        EarlGrey.selectElement(with: grey_accessibilityID("goBack")).perform(grey_tap())
        BrowserUtils.resetToAboutHome()
        BrowserUtils.clearPrivateData()
    }
}

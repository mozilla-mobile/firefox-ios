/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class DomainAutocompleteTests: KIFTestCase {
    func testAutocomplete() {
        BrowserUtils.addHistoryEntry("Mozilla", url: NSURL(string: "http://mozilla.org/")!)
        BrowserUtils.addHistoryEntry("Yahoo", url: NSURL(string: "http://www.yahoo.com/")!)
        BrowserUtils.addHistoryEntry("Foo bar baz", url: NSURL(string: "https://foo.bar.baz.org/dingbat")!)

        tester().tapViewWithAccessibilityIdentifier("url")
        let textField = tester().waitForViewWithAccessibilityLabel("Address and Search") as! UITextField

        // Basic autocompletion cases.
        tester().enterTextIntoCurrentFirstResponder("w")
        ensureAutocompletionResult(textField, prefix: "w", completion: "ww.yahoo.com/")
        tester().enterTextIntoCurrentFirstResponder("ww.yahoo.com/")
        ensureAutocompletionResult(textField, prefix: "www.yahoo.com/", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure that the scheme is included in the autocompletion.
        tester().enterTextIntoCurrentFirstResponder("https")
        ensureAutocompletionResult(textField, prefix: "https", completion: "://foo.bar.baz.org/")
        tester().clearTextFromFirstResponder()

        // Multiple subdomains.
        tester().enterTextIntoCurrentFirstResponder("f")
        ensureAutocompletionResult(textField, prefix: "f", completion: "oo.bar.baz.org/")
        tester().clearTextFromFirstResponder()
        tester().enterTextIntoCurrentFirstResponder("b")
        ensureAutocompletionResult(textField, prefix: "b", completion: "ar.baz.org/")
        tester().enterTextIntoCurrentFirstResponder("a")
        ensureAutocompletionResult(textField, prefix: "ba", completion: "r.baz.org/")
        tester().enterTextIntoCurrentFirstResponder("z")
        ensureAutocompletionResult(textField, prefix: "baz", completion: ".org/")

        // Non-matches.
        tester().enterTextIntoCurrentFirstResponder("!")
        ensureAutocompletionResult(textField, prefix: "baz!", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match against TLDs.
        tester().enterTextIntoCurrentFirstResponder("o")
        ensureAutocompletionResult(textField, prefix: "o", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match other characters.
        tester().enterTextIntoCurrentFirstResponder(".")
        ensureAutocompletionResult(textField, prefix: ".", completion: "")
        tester().clearTextFromFirstResponder()
        tester().enterTextIntoCurrentFirstResponder(":")
        ensureAutocompletionResult(textField, prefix: ":", completion: "")
        tester().clearTextFromFirstResponder()
        tester().enterTextIntoCurrentFirstResponder("/")
        ensureAutocompletionResult(textField, prefix: "/", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match letters that don't start a word.
        tester().enterTextIntoCurrentFirstResponder("a")
        ensureAutocompletionResult(textField, prefix: "a", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match words outside of the domain.
        tester().enterTextIntoCurrentFirstResponder("ding")
        ensureAutocompletionResult(textField, prefix: "ding", completion: "")
        tester().clearTextFromFirstResponder()

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    private func ensureAutocompletionResult(textField: UITextField, prefix: String, completion: String) {
        var range = NSRange()
        var attribute: AnyObject?
        let textLength = count(textField.text)

        attribute = textField.attributedText!.attribute(NSBackgroundColorAttributeName, atIndex: 0, effectiveRange: &range)

        if attribute != nil {
            // If the background attribute exists for the first character, the entire string is highlighted.
            XCTAssertEqual(prefix, "")
            XCTAssertEqual(completion, textField.text)
            return
        }

        let prefixLength = range.length

        attribute = textField.attributedText!.attribute(NSBackgroundColorAttributeName, atIndex: textLength - 1, effectiveRange: &range)

        if attribute == nil {
            // If the background attribute exists for the last character, the entire string is not highlighted.
            XCTAssertEqual(prefix, textField.text)
            XCTAssertEqual(completion, "")
            return
        }

        let completionStartIndex = advance(textField.text.startIndex, prefixLength)
        let actualPrefix = textField.text.substringToIndex(completionStartIndex)
        let actualCompletion = textField.text.substringFromIndex(completionStartIndex)

        XCTAssertEqual(prefix, actualPrefix, "Expected prefix matches actual prefix")
        XCTAssertEqual(completion, actualCompletion, "Expected completion matches actual completion")
    }
}
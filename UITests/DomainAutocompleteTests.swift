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
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "w", completion: "ww.yahoo.com/")
        tester().enterTextIntoCurrentFirstResponder("ww.yahoo.com/")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.yahoo.com/", completion: "")
        tester().clearTextFromFirstResponder()

        // Test that deleting characters works correctly with autocomplete
        tester().enterTextIntoCurrentFirstResponder("www.yah")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.yah", completion: "oo.com/")
        tester().deleteCharacterFromFirstResponser()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.yah", completion: "")
        tester().deleteCharacterFromFirstResponser()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.ya", completion: "")
        tester().enterTextIntoCurrentFirstResponder("h")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.yah", completion: "oo.com/")

        // Delete the entire string and verify that the home panels are shown again.
        tester().clearTextFromFirstResponder()
        tester().waitForViewWithAccessibilityLabel("Panel Chooser")

        // Ensure that the scheme is included in the autocompletion.
        tester().enterTextIntoCurrentFirstResponder("https")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "https", completion: "://foo.bar.baz.org/")
        tester().clearTextFromFirstResponder()

        // Multiple subdomains.
        tester().enterTextIntoCurrentFirstResponder("f")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "f", completion: "oo.bar.baz.org/")
        tester().clearTextFromFirstResponder()
        tester().enterTextIntoCurrentFirstResponder("b")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "b", completion: "ar.baz.org/")
        tester().enterTextIntoCurrentFirstResponder("a")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "ba", completion: "r.baz.org/")
        tester().enterTextIntoCurrentFirstResponder("z")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "baz", completion: ".org/")

        // Non-matches.
        tester().enterTextIntoCurrentFirstResponder("!")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "baz!", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match against TLDs.
        tester().enterTextIntoCurrentFirstResponder("org")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "org", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match other characters.
        tester().enterTextIntoCurrentFirstResponder(".")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: ".", completion: "")
        tester().clearTextFromFirstResponder()
        tester().enterTextIntoCurrentFirstResponder(":")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: ":", completion: "")
        tester().clearTextFromFirstResponder()
        tester().enterTextIntoCurrentFirstResponder("/")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "/", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match strings that don't start a word.
        tester().enterTextIntoCurrentFirstResponder("ozilla")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "ozilla", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match words outside of the domain.
        tester().enterTextIntoCurrentFirstResponder("ding")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "ding", completion: "")
        tester().clearTextFromFirstResponder()

        // Test default domains.
        tester().enterTextIntoCurrentFirstResponder("a")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "a", completion: "mazon.com/")
        tester().enterTextIntoCurrentFirstResponder("n")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "an", completion: "swers.com/")
        tester().enterTextIntoCurrentFirstResponder("c")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "anc", completion: "estry.com/")

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    override func tearDown() {
        do {
            try tester().tryFindingTappableViewWithAccessibilityLabel("Cancel")
            tester().tapViewWithAccessibilityLabel("Cancel")
        } catch _ {
        }
        BrowserUtils.clearHistoryItems(tester())
    }
}
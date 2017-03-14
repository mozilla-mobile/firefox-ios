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
        BrowserUtils.addHistoryEntry("Mozilla", url: URL(string: "http://mozilla.org/")!)
        BrowserUtils.addHistoryEntry("Yahoo", url: URL(string: "http://www.yahoo.com/")!)
        BrowserUtils.addHistoryEntry("Foo bar baz", url: URL(string: "https://foo.bar.baz.org/dingbat")!)

        tester().tapView(withAccessibilityIdentifier: "url")
        let textField = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField

        // Basic autocompletion cases.
        tester().enterText(intoCurrentFirstResponder: "w")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "w", completion: "ww.yahoo.com/")
        tester().enterText(intoCurrentFirstResponder: "ww.yahoo.com/")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.yahoo.com/", completion: "")
        tester().clearTextFromFirstResponder()

        // Test that deleting characters works correctly with autocomplete
        tester().enterText(intoCurrentFirstResponder: "www.yah")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.yah", completion: "oo.com/")
        tester().deleteCharacterFromFirstResponser()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.yah", completion: "")
        tester().deleteCharacterFromFirstResponser()
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.ya", completion: "")
        tester().enterText(intoCurrentFirstResponder: "h")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "www.yah", completion: "oo.com/")

        // Delete the entire string and verify that the home panels are shown again.
        tester().clearTextFromFirstResponder()
        tester().waitForView(withAccessibilityLabel: "Panel Chooser")

        // Ensure that the scheme is included in the autocompletion.
        tester().enterText(intoCurrentFirstResponder: "https")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "https", completion: "://foo.bar.baz.org/")
        tester().clearTextFromFirstResponder()

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

        // Non-matches.
        tester().enterText(intoCurrentFirstResponder: "!")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "baz!", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match against TLDs.
        tester().enterText(intoCurrentFirstResponder: "org")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "org", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match other characters.
        tester().enterText(intoCurrentFirstResponder: ".")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: ".", completion: "")
        tester().clearTextFromFirstResponder()
        tester().enterText(intoCurrentFirstResponder: ":")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: ":", completion: "")
        tester().clearTextFromFirstResponder()
        tester().enterText(intoCurrentFirstResponder: "/")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "/", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match strings that don't start a word.
        tester().enterText(intoCurrentFirstResponder: "ozilla")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "ozilla", completion: "")
        tester().clearTextFromFirstResponder()

        // Ensure we don't match words outside of the domain.
        tester().enterText(intoCurrentFirstResponder: "ding")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "ding", completion: "")
        tester().clearTextFromFirstResponder()

        // Test default domains.
        tester().enterText(intoCurrentFirstResponder: "a")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "a", completion: "mazon.com/")
        tester().enterText(intoCurrentFirstResponder: "n")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "an", completion: "swers.com/")
        tester().enterText(intoCurrentFirstResponder: "c")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "anc", completion: "estry.com/")
        tester().clearTextFromFirstResponder()

        // Test mixed case autocompletion.
        tester().enterText(intoCurrentFirstResponder: "YaH")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "YaH", completion: "oo.com/")
        tester().clearTextFromFirstResponder()

        // Test that leading spaces still show suggestions.
        tester().enterText(intoCurrentFirstResponder: "   yah")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "   yah", completion: "oo.com/")

        // Test that trailing spaces do *not* show suggestions.
        tester().enterText(intoCurrentFirstResponder: " ")
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "   yah ", completion: "")

        tester().tapView(withAccessibilityLabel: "Cancel")
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

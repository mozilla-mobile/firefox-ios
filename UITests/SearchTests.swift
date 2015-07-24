/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

private let LabelPrompt = "Turn on search suggestions?"
private let HintSuggestionButton = "Searches for the suggestion"

class SearchTests: KIFTestCase {
    func testOptInPrompt() {
        var found: Bool

        // Ensure that the prompt appears.
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("foobar")
        found = tester().tryFindingViewWithAccessibilityLabel(LabelPrompt, error: nil)
        XCTAssertTrue(found, "Prompt is shown")

        // Ensure that no suggestions are visible before answering the prompt.
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestion shown before prompt selection")

        // Ensure that suggestions are visible after selecting Yes.
        tester().tapViewWithAccessibilityLabel("Yes")
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertTrue(found, "Found suggestions after choosing Yes")

        tester().tapViewWithAccessibilityLabel("Cancel")

        // Return to the search screen, and make sure our choice was remembered.
        found = tester().tryFindingViewWithAccessibilityLabel(LabelPrompt, error: nil)
        XCTAssertFalse(found, "Prompt is not shown")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterText("foobar", intoViewWithAccessibilityLabel: LabelAddressAndSearch)
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertTrue(found, "Search suggestions are still enabled")

        tester().tapViewWithAccessibilityLabel("Cancel")
        resetSuggestionsPrompt()

        // Ensure that the prompt appears.
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterText("foobar", intoViewWithAccessibilityLabel: LabelAddressAndSearch)
        found = tester().tryFindingViewWithAccessibilityLabel(LabelPrompt, error: nil)
        XCTAssertTrue(found, "Prompt is shown")

        // Ensure that no suggestions are visible before answering the prompt.
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestion buttons are shown")

        // Ensure that no suggestions are visible after selecting No.
        tester().tapViewWithAccessibilityLabel("No")
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestions after choosing No")

        tester().tapViewWithAccessibilityLabel("Cancel")
        resetSuggestionsPrompt()
    }

    private func resetSuggestionsPrompt() {
        NSNotificationCenter.defaultCenter().postNotificationName("SearchEnginesPromptReset", object: nil)
    }

    override func tearDown() {
        if tester().tryFindingTappableViewWithAccessibilityLabel("Cancel", error: nil) {
            tester().tapViewWithAccessibilityLabel("Cancel")
        }
    }
}

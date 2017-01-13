/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import CoreLocation
import WebKit
@testable import Client

private let LabelPrompt = "Turn on search suggestions?"
private let HintSuggestionButton = "Searches for the suggestion"
private let LabelYahooSearchIcon = "Search suggestions from Yahoo"

class SearchTests: KIFTestCase {
    
    override func setUp() {
        super.setUp()
        BrowserUtils.dismissFirstRunUI(tester())
    }
    
    func testOptInPrompt() {
        var found: Bool

        // Ensure that the prompt appears.
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "foobar")
        found = tester().viewExistsWithLabel(LabelPrompt)
        XCTAssertTrue(found, "Prompt is shown")

        // Ensure that no suggestions are visible before answering the prompt.
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestion shown before prompt selection")

        // Ensure that suggestions are visible after selecting Yes.
        tester().tapView(withAccessibilityLabel: "Yes")
        found = tester().waitForViewWithAccessibilityHint(HintSuggestionButton) != nil
        XCTAssertTrue(found, "Found suggestions after choosing Yes")

        tester().tapView(withAccessibilityLabel: "Cancel")

        // Return to the search screen, and make sure our choice was remembered.
        found = tester().viewExistsWithLabel(LabelPrompt)

        XCTAssertFalse(found, "Prompt is not shown")
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearText(fromAndThenEnterText: "foobar", intoViewWithAccessibilityLabel: LabelAddressAndSearch)
        found = tester().waitForViewWithAccessibilityHint(HintSuggestionButton) != nil
        XCTAssertTrue(found, "Search suggestions are still enabled")
        tester().tapView(withAccessibilityLabel: "Cancel")
        resetSuggestionsPrompt()

        // Ensure that the prompt appears.
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearText(fromAndThenEnterText: "foobar", intoViewWithAccessibilityLabel: LabelAddressAndSearch)

        found = tester().viewExistsWithLabel(LabelPrompt)
        XCTAssertTrue(found, "Prompt is shown")

        // Ensure that no suggestions are visible before answering the prompt.
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestion buttons are shown")

        // Ensure that no suggestions are visible after selecting No.
        tester().tapView(withAccessibilityLabel: "No")
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestions after choosing No")
    }
/*
    func testChangingDyamicFontOnSearch() {
        DynamicFontUtils.restoreDynamicFontSize(tester())

        // Ensure that the prompt appears.
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("foobar")
        waitForPotentialDebounce(tester())
        tester().tapViewWithAccessibilityLabel("Yes")

        let size = getFirstSuggestionButton(tester())?.titleLabel?.font.pointSize

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = getFirstSuggestionButton(tester())?.titleLabel?.font.pointSize

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = getFirstSuggestionButton(tester())?.titleLabel?.font.pointSize

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)
    }
*/
    func testTurnOffSuggestionsWhenEnteringURL() {
        var found: Bool
        
        // Ensure that the prompt appears.
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "foobar")
        found = tester().viewExistsWithLabel(LabelPrompt)
        XCTAssertTrue(found, "Prompt is shown")

        // Ensure that no suggestions are visible before answering the prompt.
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "No suggestion shown before prompt selection")

        // Ensure that suggestions are visible after selecting Yes.
        tester().tapView(withAccessibilityLabel: "Yes")
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertTrue(found, "Found suggestions after choosing Yes")
        found = tester().viewExistsWithLabel(LabelYahooSearchIcon)
        XCTAssertTrue(found, "Found search provider icon")

        tester().tapView(withAccessibilityLabel: "Address and Search")
        tester().enterText(intoCurrentFirstResponder: "/")

        // Wait for debounce in case
        waitForPotentialDebounce(tester())
        found = tester().tryFindingViewWithAccessibilityHint(HintSuggestionButton)
        XCTAssertFalse(found, "Found suggestions after adding / to url")
        found = tester().viewExistsWithLabel(LabelYahooSearchIcon)
        XCTAssertFalse(found, "Found no search provider icon")

        tester().tapView(withAccessibilityLabel: "Address and Search")
        tester().enterText(intoCurrentFirstResponder: " ")

        // Wait for debounce in case
        tester().wait(forTimeInterval: 0.3)

        found = tester().viewExistsWithLabel(LabelYahooSearchIcon)
        XCTAssertTrue(found, "Found search provider icon after making input url invalid")
    }

    func testURLBarContextMenu() {
        let webRoot = SimplePageServer.start()
        let testURL = "\(webRoot)/numberedPage.html?page=1"

        // Verify that Paste & Go goes to the URL.
        UIPasteboard.general.string = testURL
        tester().longPressView(withAccessibilityIdentifier: "url", duration: 1)
        tester().tapView(withAccessibilityLabel: "Paste & Go")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Verify that Paste shows the search controller with prompt.
        var promptFound = tester().viewExistsWithLabel(LabelPrompt)

        XCTAssertFalse(promptFound, "Search prompt is not shown")
        UIPasteboard.general.string = "http"
        tester().longPressView(withAccessibilityIdentifier: "url", duration: 1)
        tester().tapView(withAccessibilityLabel: "Paste")
        promptFound = tester().waitForView(withAccessibilityLabel: LabelPrompt) != nil
        XCTAssertTrue(promptFound, "Search prompt is shown")

        // Verify that Paste triggers an autocompletion, with the correct highlighted portion.
        let textField = tester().waitForView(withAccessibilityLabel: LabelAddressAndSearch) as! UITextField
        let expectedString = "\(webRoot)/"
        let endingString = expectedString.substring(from: expectedString.characters.index(expectedString.startIndex, offsetBy: "http".characters.count))
        BrowserUtils.ensureAutocompletionResult(tester(), textField: textField, prefix: "http", completion: endingString)

        tester().tapView(withAccessibilityLabel: "Cancel", traits: UIAccessibilityTraitButton)

        // Verify that Copy Address copies the text to the clipboard.
        XCTAssertNotEqual(UIPasteboard.general.string!, testURL, "URL is not in clipboard")
        tester().longPressView(withAccessibilityIdentifier: "url", duration: 1)
        tester().tapView(withAccessibilityLabel: "Copy Address")
        XCTAssertEqual(UIPasteboard.general.string!, testURL, "URL is in clipboard")

        // Verify that in-editing Paste shows the search controller with prompt.
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromFirstResponder()
        tester().waitForAbsenceOfView(withAccessibilityLabel: LabelPrompt)
        promptFound = tester().viewExistsWithLabel(LabelPrompt)
        XCTAssertFalse(promptFound, "Search prompt is not shown")
        tester().tapView(withAccessibilityLabel: LabelAddressAndSearch)
        tester().tapView(withAccessibilityLabel: "Paste")
        promptFound = tester().waitForView(withAccessibilityLabel: LabelPrompt) != nil
        XCTAssertTrue(promptFound, "Search prompt is shown")
    }

    func searchForTerms(_ terms: String, withSearchEngine engine: String) {
        SearchUtils.navigateToSearchSettings(tester())
        SearchUtils.selectDefaultSearchEngineName(tester(), engineName: engine)
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")

        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(terms)\n")
        tester().wait(forTimeInterval: 3.0)

        tester().tapView(withAccessibilityIdentifier: "url")
        let textField = tester().waitForView(withAccessibilityLabel: LabelAddressAndSearch) as! UITextField
        let pos = textField.text!.lowercased().range(of: "foobar")
        XCTAssertTrue(pos != nil)
        tester().tapView(withAccessibilityLabel: "Cancel")
        BrowserUtils.resetToAboutHome(tester())
    }

    // The location access request from Bing causes system/browser confirmation dialogs that KIFTest cannot handle reliably
    func testSearchTermExtractionDisplaysInURLBar() {
        let searchTerms = "foobar"
        searchForTerms(searchTerms, withSearchEngine: "Amazon.com")
        searchForTerms(searchTerms, withSearchEngine: "DuckDuckGo")
        searchForTerms(searchTerms, withSearchEngine: "Google")
        searchForTerms(searchTerms, withSearchEngine: "Twitter")
        searchForTerms(searchTerms, withSearchEngine: "Wikipedia")
        searchForTerms(searchTerms, withSearchEngine: "Yahoo")
        //searchForTerms(searchTerms, withSearchEngine: "Bing")
    }

    fileprivate func waitForPotentialDebounce(_ tester: KIFUITestActor) {
        tester.wait(forTimeInterval: 1.3)
    }

    fileprivate func resetSuggestionsPrompt() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SearchEnginesPromptReset"), object: nil)
    }

    fileprivate func getFirstSuggestionButton(_ tester: KIFUITestActor) -> UIButton? {
        return tester.waitForViewWithAccessibilityHint(HintSuggestionButton) as? UIButton
    }

    override func tearDown() {
        //DynamicFontUtils.restoreDynamicFontSize(tester())
        resetSuggestionsPrompt()
        
        if SearchUtils.getDefaultEngine().shortName != "Yahoo" {
            SearchUtils.navigateToSearchSettings(tester())
            SearchUtils.selectDefaultSearchEngineName(tester(), engineName: "Yahoo")
            tester().tapView(withAccessibilityLabel: "Settings")
            tester().tapView(withAccessibilityLabel: "Done")
        }
        
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}

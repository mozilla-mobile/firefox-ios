// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol QuickAnswersSelectorsSet {
    var OPT_IN_SHEET_TITLE: Selector { get }
    var CLOSE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct QuickAnswersSelectors: QuickAnswersSelectorsSet {
    private enum IDs {
        static let optInSheetTitle = String.QuickAnswers.OptInRedesign.Title
        static let closeButton = String.QuickAnswers.AccessibilityLabels.Close
    }

    let OPT_IN_SHEET_TITLE = Selector.staticTextByExactLabel(
        IDs.optInSheetTitle,
        description: "Title of the Quick Answers opt-in sheet",
        groups: ["quick_answers"]
    )

    // Shared by the opt-in sheet and the Quick Answers screen behind it, which have no identifiers.
    let CLOSE_BUTTON = Selector.buttonByLabel(
        IDs.closeButton,
        description: "'X' close button of the Quick Answers opt-in sheet and screen",
        groups: ["quick_answers"]
    )

    var all: [Selector] { [OPT_IN_SHEET_TITLE, CLOSE_BUTTON] }
}

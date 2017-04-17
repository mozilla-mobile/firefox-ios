/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class BlockzillaTests: XCTestCase {
    func testSupportUtilsURLForTopic() {
        // focusHelp - No German
        XCTAssertEqual(SupportTopic.focusHelp.URLForLanguageCode("en"), URL(string: "https://support.mozilla.org/kb/focus"))          // Default
        XCTAssertEqual(SupportTopic.focusHelp.URLForLanguageCode("de"), URL(string: "https://support.mozilla.org/kb/focus"))          // Default
        XCTAssertEqual(SupportTopic.focusHelp.URLForLanguageCode("es"), URL(string: "https://support.mozilla.org/kb/focus-es"))       // Simple
        XCTAssertEqual(SupportTopic.focusHelp.URLForLanguageCode("es-MX"), URL(string: "https://support.mozilla.org/kb/focus-es"))    // Language-Region
        XCTAssertEqual(SupportTopic.focusHelp.URLForLanguageCode("hi"), URL(string: "https://support.mozilla.org/kb/focus-hi-in"))    // Language-Region
        XCTAssertEqual(SupportTopic.focusHelp.URLForLanguageCode("zh-TW"), URL(string: "https://support.mozilla.org/kb/focus-zh-tw")) // Language-Region

        // klarHelp - Only German
        XCTAssertEqual(SupportTopic.klarHelp.URLForLanguageCode("de"), URL(string: "https://support.mozilla.org/kb/klar"))
        XCTAssertEqual(SupportTopic.klarHelp.URLForLanguageCode("de-CH"), URL(string: "https://support.mozilla.org/kb/klar"))
        XCTAssertEqual(SupportTopic.klarHelp.URLForLanguageCode("en"), URL(string: "https://support.mozilla.org/kb/klar"))
    }
}

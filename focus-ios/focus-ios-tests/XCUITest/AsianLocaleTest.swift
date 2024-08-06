/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class AsianLocaleTest: BaseTestCase {
    let locales: [String: String]  = [
        "Korean": "모질라",
        "Japanese": "モジラ",
        "Chinese": "因特網"
    ]

    func searchForMozillaInLocale(localeName: String, searchText: String) {
        let urlBarDeleteButton = app.eraseButton

        search(searchWord: searchText, waitForLoadToFinish: true)
        mozTap(urlBarDeleteButton)
        dismissURLBarFocused()
        checkForHomeScreen()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2599440
    func testSearchInLocale() {
        // Test Setup
        dismissURLBarFocused()
        checkForHomeScreen()
        navigateToSettingSearchEngine()
        setDefaultSearchEngine(searchEngine: "Google")

        // Test Steps
        for (localeName, searchText) in locales {
            searchForMozillaInLocale(localeName: localeName, searchText: searchText)
        }
    }
}

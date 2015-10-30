/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchSettingsUITests: KIFTestCase {

    func testDefaultSearchEngine() {
        SearchUtils.navigateToSearchSettings(tester())
        SearchUtils.selectDefaultSearchEngineName(tester(), engineName: "Yahoo")
        XCTAssertEqual("Yahoo", SearchUtils.getDefaultSearchEngineName(tester()))
        SearchUtils.selectDefaultSearchEngineName(tester(), engineName: "Amazon.com")
        XCTAssertEqual("Amazon.com", SearchUtils.getDefaultSearchEngineName(tester()))
        SearchUtils.selectDefaultSearchEngineName(tester(), engineName: "Yahoo")
        XCTAssertEqual("Yahoo", SearchUtils.getDefaultSearchEngineName(tester()))
        SearchUtils.navigateFromSearchSettings(tester())
    }
}

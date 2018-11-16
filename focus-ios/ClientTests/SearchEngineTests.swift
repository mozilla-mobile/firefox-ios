/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class SearchEngineTests: XCTestCase {
    private let engine = SearchEngineManager(prefs: UserDefaults.standard).activeEngine
    private let client = SearchSuggestClient()
    
    private let SPECIAL_CHAR_SEARCH = "\""
    private let NORMAL_SEARCH = "example"
    private let BEGIN_WITH_WHITE_SPACE_SEARCH = " example"

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSpecialCharacterQuery() {
        let queryURL = engine.urlForQuery(SPECIAL_CHAR_SEARCH)
        XCTAssertNotNil(queryURL)
    }
    
    func testSpecialCharacterSearchSuggestions() {
        let searchURL = engine.urlForSuggestions(SPECIAL_CHAR_SEARCH)
        XCTAssertNotNil(searchURL)
    }
    
    func testNormalQuery() {
        let queryURL = engine.urlForQuery(NORMAL_SEARCH)
        XCTAssertNotNil(queryURL)
    }
    
    func testNormalSearchSuggestions() {
        let searchURL = engine.urlForSuggestions(NORMAL_SEARCH)
        XCTAssertNotNil(searchURL)
    }
    
    func testBeginWithWhiteSpaceQuery() {
        let normalQueryURL = engine.urlForQuery(NORMAL_SEARCH)
        let testQueryURL = engine.urlForQuery(BEGIN_WITH_WHITE_SPACE_SEARCH)
        XCTAssertEqual(normalQueryURL, testQueryURL)
    }
    
    func testBeginWithWhiteSpaceSearchSuggestions() {
        let normalSearchURL = engine.urlForSuggestions(NORMAL_SEARCH)
        let testSearchURL = engine.urlForSuggestions(BEGIN_WITH_WHITE_SPACE_SEARCH)
        XCTAssertEqual(normalSearchURL, testSearchURL)
    }

    func testGetSuggestions() {
        client.getSuggestions(NORMAL_SEARCH, callback: { response, error in
            XCTAssertThrowsError(error)
            XCTAssertNil(response)
        })
    }
        
    func testResponseConsistency() {
        let client = SearchSuggestClient()
        client.getSuggestions(NORMAL_SEARCH, callback: { response, error in
            XCTAssertThrowsError(error)
            XCTAssertEqual(self.NORMAL_SEARCH, response?[0])
        })
    }
}

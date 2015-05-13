/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Shared

private let DefaultSearchEngineName = "Yahoo"
private let ExpectedEngineNames = ["Amazon.com", "Bing", "DuckDuckGo", "Google", "Twitter", "Wikipedia", "Yahoo"]

class SearchEnginesTests: XCTestCase {
    func testIncludesExpectedEngines() {
        // Verify that the set of shipped engines includes the expected subset.
        let engines = SearchEngines(prefs: MockProfilePrefs()).orderedEngines
        XCTAssertTrue(engines.count >= ExpectedEngineNames.count)

        for engineName in ExpectedEngineNames {
            XCTAssertTrue((engines.filter { engine in engine.shortName == engineName }).count > 0)
        }
    }

    func testDefaultEngineOnStartup() {
        // If this is our first run, Yahoo should be first for the en locale.
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)
        XCTAssertEqual(engines.defaultEngine.shortName, DefaultSearchEngineName)
        XCTAssertEqual(engines.orderedEngines[0].shortName, DefaultSearchEngineName)
    }

    func testDefaultEngine() {
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)
        let engineSet = engines.orderedEngines

        engines.defaultEngine = engineSet[0]
        XCTAssertTrue(engines.isEngineDefault(engineSet[0]))
        XCTAssertFalse(engines.isEngineDefault(engineSet[1]))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet[0].shortName)

        engines.defaultEngine = engineSet[1]
        XCTAssertFalse(engines.isEngineDefault(engineSet[0]))
        XCTAssertTrue(engines.isEngineDefault(engineSet[1]))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet[1].shortName)

        let engines2 = SearchEngines(prefs: prefs)
        // The default engine should have been persisted.
        XCTAssertTrue(engines2.isEngineDefault(engineSet[1]))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet[1].shortName)
    }

    func testOrderedEngines() {
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)

        engines.orderedEngines = [ExpectedEngineNames[4], ExpectedEngineNames[2], ExpectedEngineNames[0]].map { name in
            for engine in engines.orderedEngines {
                if engine.shortName == name {
                    return engine
                }
            }
            XCTFail("Could not find engine: \(name)")
            return engines.orderedEngines.first!
        }
        XCTAssertEqual(engines.orderedEngines[0].shortName, ExpectedEngineNames[4])
        XCTAssertEqual(engines.orderedEngines[1].shortName, ExpectedEngineNames[2])
        XCTAssertEqual(engines.orderedEngines[2].shortName, ExpectedEngineNames[0])

        let engines2 = SearchEngines(prefs: prefs)
        // The ordering should have been persisted.
        XCTAssertEqual(engines2.orderedEngines[0].shortName, ExpectedEngineNames[4])
        XCTAssertEqual(engines2.orderedEngines[1].shortName, ExpectedEngineNames[2])
        XCTAssertEqual(engines2.orderedEngines[2].shortName, ExpectedEngineNames[0])

        // Remaining engines should be appended in alphabetical order.
        XCTAssertEqual(engines2.orderedEngines[3].shortName, ExpectedEngineNames[1])
        XCTAssertEqual(engines2.orderedEngines[4].shortName, ExpectedEngineNames[3])
        XCTAssertEqual(engines2.orderedEngines[5].shortName, ExpectedEngineNames[5])
        XCTAssertEqual(engines2.orderedEngines[6].shortName, ExpectedEngineNames[6])
    }

    func testQuickSearchEngines() {
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)
        let engineSet = engines.orderedEngines

        // You can't disable the default engine.
        engines.defaultEngine = engineSet[1]
        engines.disableEngine(engineSet[1])
        XCTAssertTrue(engines.isEngineEnabled(engineSet[1]))

        // The default engine is not included in the quick search engines.
        XCTAssertEqual(0, engines.quickSearchEngines.filter { engine in engine.shortName == engineSet[1].shortName }.count)

        // Enable and disable work.
        engines.enableEngine(engineSet[0])
        XCTAssertTrue(engines.isEngineEnabled(engineSet[0]))
        XCTAssertEqual(1, engines.quickSearchEngines.filter { engine in engine.shortName == engineSet[0].shortName }.count)

        engines.disableEngine(engineSet[0])
        XCTAssertFalse(engines.isEngineEnabled(engineSet[0]))
        XCTAssertEqual(0, engines.quickSearchEngines.filter { engine in engine.shortName == engineSet[0].shortName }.count)

        // Setting the default engine enables it.
        engines.defaultEngine = engineSet[0]
        XCTAssertTrue(engines.isEngineEnabled(engineSet[1]))

        // Setting the order may change the default engine, which enables it.
        engines.orderedEngines = [engineSet[2], engineSet[1], engineSet[0]]
        XCTAssertTrue(engines.isEngineDefault(engineSet[2]))
        XCTAssertTrue(engines.isEngineEnabled(engineSet[2]))

        // The enabling should be persisted.
        engines.enableEngine(engineSet[2])
        engines.disableEngine(engineSet[1])
        engines.enableEngine(engineSet[0])

        let engines2 = SearchEngines(prefs: prefs)
        XCTAssertTrue(engines2.isEngineEnabled(engineSet[2]))
        XCTAssertFalse(engines2.isEngineEnabled(engineSet[1]))
        XCTAssertTrue(engines2.isEngineEnabled(engineSet[0]))
    }

    func testSearchSuggestionSettings() {
        let prefs = MockProfilePrefs()
        let engines = SearchEngines(prefs: prefs)

        // By default, you should see an opt-in, and suggestions are disabled.
        XCTAssertTrue(engines.shouldShowSearchSuggestionsOptIn)
        XCTAssertFalse(engines.shouldShowSearchSuggestions)

        // Setting should be persisted.
        engines.shouldShowSearchSuggestionsOptIn = false
        engines.shouldShowSearchSuggestions = true

        let engines2 = SearchEngines(prefs: prefs)
        XCTAssertFalse(engines2.shouldShowSearchSuggestionsOptIn)
        XCTAssertTrue(engines2.shouldShowSearchSuggestions)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import XCTest
import Shared

class SearchEnginesManagerTests: XCTestCase {
    private let defaultSearchEngineName = "ATester"
    private let expectedEngineNames = ["ATester", "BTester", "CTester", "DTester", "ETester", "FTester"]
    private var profile: Profile!
    private var searchEnginesManager: SearchEnginesManager!
    private var orderedEngines: [OpenSearchEngine]!
    private var mockSearchEngineProvider: MockSearchEngineProvider!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        mockSearchEngineProvider = MockSearchEngineProvider()
        searchEnginesManager = SearchEnginesManager(
            prefs: profile.prefs,
            files: profile.files,
            engineProvider: mockSearchEngineProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        mockSearchEngineProvider = nil
        searchEnginesManager = nil
    }

    func testIncludesExpectedEngines() {
        // Verify that the set of shipped engines includes the expected subset.
        let expectation = expectation(description: "Completed parse engines")

        searchEnginesManager.getOrderedEngines { prefs, result in
            XCTAssertEqual(self.searchEnginesManager.orderedEngines.count, 6)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testDefaultEngineOnStartup() {
        // If this is our first run, Google should be first for the en locale.
        XCTAssertEqual(searchEnginesManager.defaultEngine?.shortName, defaultSearchEngineName)
        XCTAssertEqual(searchEnginesManager.orderedEngines[0].shortName, defaultSearchEngineName)
    }

    func testAddingAndDeletingCustomEngines() {
        guard let testImage = UIImage(named: "wikipedia", in: Bundle(for: SearchEnginesManagerTests.self), with: nil) else {
            XCTFail("Check that image is bundled for testing")
            return
        }
        let testEngine = OpenSearchEngine(engineID: "ATester",
                                          shortName: "ATester",
                                          image: testImage,
                                          searchTemplate: "http://firefox.com/find?q={searchTerm}",
                                          suggestTemplate: nil,
                                          isCustomEngine: true)

        searchEnginesManager.orderedEngines[0] = testEngine
        searchEnginesManager.addSearchEngine(testEngine)
        XCTAssertEqual(searchEnginesManager.orderedEngines[1].engineID, testEngine.engineID)

        var deleted: [OpenSearchEngine] = []
        searchEnginesManager.deleteCustomEngine(testEngine) { [self] in
            deleted = searchEnginesManager.orderedEngines.filter { $0 == testEngine }
        }

        XCTAssertEqual(deleted, [])
    }

    func testDefaultEngine() {
        let engineSet = searchEnginesManager.orderedEngines

        searchEnginesManager.defaultEngine = engineSet[0]
        XCTAssertTrue(searchEnginesManager.isEngineDefault(engineSet[0]))
        XCTAssertFalse(searchEnginesManager.isEngineDefault(engineSet[1]))
        // The first ordered engine is the default.
        XCTAssertEqual(searchEnginesManager.orderedEngines[0].shortName, engineSet[0].shortName)

        searchEnginesManager.defaultEngine = engineSet[1]
        XCTAssertFalse(searchEnginesManager.isEngineDefault(engineSet[0]))
        XCTAssertTrue(searchEnginesManager.isEngineDefault(engineSet[1]))
        // The first ordered engine is the default.
        XCTAssertEqual(searchEnginesManager.orderedEngines[0].shortName, engineSet[1].shortName)

        // Persistence can't be tested without the fixture changing.
    }

    func testOrderedEngines() {
        // Persistence can't be tested without the default fixture changing.
        // Remaining engines should be appended in alphabetical order.
        let expectation = expectation(description: "Completed parse engines")
        searchEnginesManager.getOrderedEngines { [weak self] prefs, orderedEngines in
            guard let self = self else {
                XCTFail("Could not weakify self.")
                return
            }
            XCTAssertEqual(orderedEngines[3].shortName, self.expectedEngineNames[3])
            XCTAssertEqual(orderedEngines[4].shortName, self.expectedEngineNames[4])
            XCTAssertEqual(orderedEngines[5].shortName, self.expectedEngineNames[5])

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testQuickSearchEngines() {
        let engineSet = searchEnginesManager.orderedEngines

        // You can't disable the default engine.
        searchEnginesManager.defaultEngine = engineSet[1]
        searchEnginesManager.disableEngine(engineSet[1])
        XCTAssertTrue(searchEnginesManager.isEngineEnabled(engineSet[1]))

        // The default engine is not included in the quick search engines.
        XCTAssertEqual(
            0,
            searchEnginesManager.quickSearchEngines.filter { engine in engine.shortName == engineSet[1].shortName }.count)

        // Enable and disable work.
        searchEnginesManager.enableEngine(engineSet[0])
        XCTAssertTrue(searchEnginesManager.isEngineEnabled(engineSet[0]))
        XCTAssertEqual(
            1,
            searchEnginesManager.quickSearchEngines.filter { engine in engine.shortName == engineSet[0].shortName }.count)

        searchEnginesManager.disableEngine(engineSet[0])
        XCTAssertFalse(searchEnginesManager.isEngineEnabled(engineSet[0]))
        XCTAssertEqual(
            0,
            searchEnginesManager.quickSearchEngines.filter { engine in engine.shortName == engineSet[0].shortName }.count)
        // Setting the default engine enables it.
        searchEnginesManager.defaultEngine = engineSet[0]
        XCTAssertTrue(searchEnginesManager.isEngineEnabled(engineSet[1]))

        // Setting the order may change the default engine, which enables it.
        searchEnginesManager.orderedEngines = [engineSet[2], engineSet[1], engineSet[0]]
        XCTAssertTrue(searchEnginesManager.isEngineDefault(engineSet[2]))
        XCTAssertTrue(searchEnginesManager.isEngineEnabled(engineSet[2]))

        // The enabling should be persisted.
        searchEnginesManager.enableEngine(engineSet[2])
        searchEnginesManager.disableEngine(engineSet[1])
        searchEnginesManager.enableEngine(engineSet[0])

        let engines2 = SearchEnginesManager(prefs: profile.prefs, files: profile.files)
        XCTAssertTrue(engines2.isEngineEnabled(engineSet[2]))
        XCTAssertFalse(engines2.isEngineEnabled(engineSet[1]))
        XCTAssertTrue(engines2.isEngineEnabled(engineSet[0]))
    }

    func testSearchSuggestionSettings() {
        // By default, you should see search suggestions
        XCTAssertTrue(searchEnginesManager.shouldShowSearchSuggestions)

        // Persistence can't be tested without the default fixture changing.
        // Setting should be persisted.
        searchEnginesManager.shouldShowSearchSuggestions = false
        XCTAssertFalse(searchEnginesManager.shouldShowSearchSuggestions)
    }

    func testShowSearchSuggestionSettingsInPrivateMode() {
        // Disable search suggestions by default
        XCTAssertFalse(searchEnginesManager.shouldShowPrivateModeSearchSuggestions)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions), false)

        // Turn off setting
        searchEnginesManager.shouldShowPrivateModeSearchSuggestions = false
        XCTAssertFalse(searchEnginesManager.shouldShowPrivateModeSearchSuggestions)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions), false)

        // Turn on setting
        searchEnginesManager.shouldShowPrivateModeSearchSuggestions = true
        XCTAssertTrue(searchEnginesManager.shouldShowPrivateModeSearchSuggestions)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions), true)
    }

    func testGetOrderedEngines() {
        // Verify that the set of shipped engines includes the expected subset.
        let expectation = expectation(description: "Completed parse engines")

        searchEnginesManager.getOrderedEngines { prefs, result in
            XCTAssert(self.searchEnginesManager.orderedEngines.count > 1, "There should be more than one search engine")
            XCTAssertEqual(self.searchEnginesManager.orderedEngines.first?.shortName, "ATester")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}

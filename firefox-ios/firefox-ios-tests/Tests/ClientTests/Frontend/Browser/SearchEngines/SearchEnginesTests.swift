// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import XCTest
import Shared

class SearchEnginesTests: XCTestCase {
    private let defaultSearchEngineName = "ATester"
    private let expectedEngineNames = ["ATester", "BTester", "CTester", "DTester", "ETester", "FTester"]
    private var profile: Profile!
    private var engines: SearchEngines!
    private var orderedEngines: [OpenSearchEngine]!
    private var mockSearchEngineProvider: MockSearchEngineProvider!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        mockSearchEngineProvider = MockSearchEngineProvider()
        engines = SearchEngines(
            prefs: profile.prefs,
            files: profile.files,
            engineProvider: mockSearchEngineProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        mockSearchEngineProvider = nil
        engines = nil
    }

    func testIncludesExpectedEngines() {
        // Verify that the set of shipped engines includes the expected subset.
        let expectation = expectation(description: "Completed parse engines")

        engines.getOrderedEngines { result in
            XCTAssertEqual(self.engines.orderedEngines.count, 6)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testDefaultEngineOnStartup() {
        // If this is our first run, Google should be first for the en locale.
        XCTAssertEqual(engines.defaultEngine?.shortName, defaultSearchEngineName)
        XCTAssertEqual(engines.orderedEngines[0].shortName, defaultSearchEngineName)
    }

    func testAddingAndDeletingCustomEngines() {
        guard let testImage = UIImage(named: "wikipedia", in: Bundle(for: SearchEnginesTests.self), with: nil) else {
            XCTFail("Check that image is bundled for testing")
            return
        }
        let testEngine = OpenSearchEngine(engineID: "ATester",
                                          shortName: "ATester",
                                          image: testImage,
                                          searchTemplate: "http://firefox.com/find?q={searchTerm}",
                                          suggestTemplate: nil,
                                          isCustomEngine: true)

        engines.orderedEngines[0] = testEngine
        engines.addSearchEngine(testEngine)
        XCTAssertEqual(engines.orderedEngines[1].engineID, testEngine.engineID)

        var deleted: [OpenSearchEngine] = []
        engines.deleteCustomEngine(testEngine) { [self] in
            deleted = engines.orderedEngines.filter { $0 == testEngine }
        }

        XCTAssertEqual(deleted, [])
    }

    func testDefaultEngine() {
        let engineSet = engines.orderedEngines

        engines.defaultEngine = (engineSet?[0])!
        XCTAssertTrue(engines.isEngineDefault((engineSet?[0])!))
        XCTAssertFalse(engines.isEngineDefault((engineSet?[1])!))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet?[0].shortName)

        engines.defaultEngine = (engineSet?[1])!
        XCTAssertFalse(engines.isEngineDefault((engineSet?[0])!))
        XCTAssertTrue(engines.isEngineDefault((engineSet?[1])!))
        // The first ordered engine is the default.
        XCTAssertEqual(engines.orderedEngines[0].shortName, engineSet?[1].shortName)

        // Persistence can't be tested without the fixture changing. 
    }

    func testOrderedEngines() {
        // Persistence can't be tested without the default fixture changing.
        // Remaining engines should be appended in alphabetical order.
        let expectation = expectation(description: "Completed parse engines")
        engines.getOrderedEngines { [weak self] orderedEngines in
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
        let engineSet = engines.orderedEngines

        // You can't disable the default engine.
        engines.defaultEngine = (engineSet?[1])!
        engines.disableEngine((engineSet?[1])!)
        XCTAssertTrue(engines.isEngineEnabled((engineSet?[1])!))

        // The default engine is not included in the quick search engines.
        XCTAssertEqual(
            0,
            engines.quickSearchEngines.filter { engine in engine.shortName == engineSet?[1].shortName }.count)

        // Enable and disable work.
        engines.enableEngine((engineSet?[0])!)
        XCTAssertTrue(engines.isEngineEnabled((engineSet?[0])!))
        XCTAssertEqual(
            1,
            engines.quickSearchEngines.filter { engine in engine.shortName == engineSet?[0].shortName }.count)

        engines.disableEngine((engineSet?[0])!)
        XCTAssertFalse(engines.isEngineEnabled((engineSet?[0])!))
        XCTAssertEqual(
            0,
            engines.quickSearchEngines.filter { engine in engine.shortName == engineSet?[0].shortName }.count)
        // Setting the default engine enables it.
        engines.defaultEngine = (engineSet?[0])!
        XCTAssertTrue(engines.isEngineEnabled((engineSet?[1])!))

        // Setting the order may change the default engine, which enables it.
        engines.orderedEngines = [(engineSet?[2])!, (engineSet?[1])!, (engineSet?[0])!]
        XCTAssertTrue(engines.isEngineDefault((engineSet?[2])!))
        XCTAssertTrue(engines.isEngineEnabled((engineSet?[2])!))

        // The enabling should be persisted.
        engines.enableEngine((engineSet?[2])!)
        engines.disableEngine((engineSet?[1])!)
        engines.enableEngine((engineSet?[0])!)

        let engines2 = SearchEngines(prefs: profile.prefs, files: profile.files)
        XCTAssertTrue(engines2.isEngineEnabled((engineSet?[2])!))
        XCTAssertFalse(engines2.isEngineEnabled((engineSet?[1])!))
        XCTAssertTrue(engines2.isEngineEnabled((engineSet?[0])!))
    }

    func testSearchSuggestionSettings() {
        // By default, you should see search suggestions
        XCTAssertTrue(engines.shouldShowSearchSuggestions)

        // Persistence can't be tested without the default fixture changing.
        // Setting should be persisted.
        engines.shouldShowSearchSuggestions = false
        XCTAssertFalse(engines.shouldShowSearchSuggestions)
    }

    func testShowSearchSuggestionSettingsInPrivateMode() {
        // Disable search suggestions by default
        XCTAssertFalse(engines.shouldShowPrivateModeSearchSuggestions)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions), false)

        // Turn off setting
        engines.shouldShowPrivateModeSearchSuggestions = false
        XCTAssertFalse(engines.shouldShowPrivateModeSearchSuggestions)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions), false)

        // Turn on setting
        engines.shouldShowPrivateModeSearchSuggestions = true
        XCTAssertTrue(engines.shouldShowPrivateModeSearchSuggestions)
        XCTAssertEqual(profile.prefs.boolForKey(PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions), true)
    }

    func testGetOrderedEngines() {
        // Verify that the set of shipped engines includes the expected subset.
        let expectation = expectation(description: "Completed parse engines")

        engines.getOrderedEngines { result in
            XCTAssert(self.engines.orderedEngines.count > 1, "There should be more than one search engine")
            XCTAssertEqual(self.engines.orderedEngines.first?.shortName, "ATester")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}

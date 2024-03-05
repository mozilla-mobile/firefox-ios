/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class SearchEngineManagerTests: XCTestCase {
    private var mockUserDefaults = MockUserDefaults()
    private let CUSTOM_ENGINE_NAME = "a custom engine name"
    private let CUSTOM_ENGINE_TEMPLATE = "http://www.example.com/%s"

    override func setUp() {
        super.setUp()
        mockUserDefaults.clear()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAddEngine() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let engine = manager.addEngine(name: CUSTOM_ENGINE_NAME, template: CUSTOM_ENGINE_TEMPLATE)

        // Verify that the engine is in the in-memory list
        XCTAssertTrue(manager.engines.contains(engine))

        // Verify that the engine is set as the active engine
        XCTAssertEqual(manager.activeEngine.name, CUSTOM_ENGINE_NAME)

        // Verify that the engine is set to be a custom engine
        XCTAssertTrue(manager.activeEngine.isCustom)

        // Verify that it persisted the custom engine and updated the default engine
        XCTAssertEqual(mockUserDefaults.setCalls, 4)
    }

    func testRemoveDefaultEngine() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let engineToRemove = manager.engines[1]
        manager.removeEngine(engine: engineToRemove)

        XCTAssertEqual(mockUserDefaults.setCalls, 3)
        XCTAssertFalse(manager.engines.contains(where: { (engine) -> Bool in
            return engine.name == engineToRemove.name
        }))
    }

    func testRemoveCustomEngine() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let engineAdded = manager.addEngine(name: CUSTOM_ENGINE_NAME, template: CUSTOM_ENGINE_TEMPLATE)
        manager.activeEngine = manager.engines[1]
        manager.removeEngine(engine: engineAdded)

        XCTAssertEqual(mockUserDefaults.setCalls, 6)
        XCTAssertFalse(manager.engines.contains(where: { (engine) -> Bool in
            return engine.name == engineAdded.name
        }))
    }

    func testResetDefaultEngines() throws {
        throw XCTSkip("Disabled due to failure: 2352")
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let numberOfEngines = manager.engines.count
        let engineToRemove = manager.engines[1]
        manager.removeEngine(engine: engineToRemove)

        XCTAssertEqual(manager.engines.count, numberOfEngines-1)
        manager.restoreDisabledDefaultEngines()
        XCTAssertEqual(manager.engines.count, numberOfEngines)
    }

    func testCanNotRemoveActiveEngine() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let numberOfEngines = manager.engines.count
        let activeEngine = manager.activeEngine
        manager.removeEngine(engine: activeEngine)

        XCTAssertEqual(manager.engines.count, numberOfEngines)
        XCTAssertEqual(manager.activeEngine.name, activeEngine.name)
        XCTAssertEqual(mockUserDefaults.setCalls, 2)
    }

    func testEmptyIsNotValidSearchEngineName() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        XCTAssertFalse(manager.isValidSearchEngineName(""))
    }
    /* Disable temporary while tests run in parallel and this fails intermittently
    func testCustomEngineIsNotValidSearchEngineName() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        XCTAssertTrue(manager.isValidSearchEngineName(CUSTOM_ENGINE_NAME))
        _ = manager.addEngine(name: CUSTOM_ENGINE_NAME, template: CUSTOM_ENGINE_TEMPLATE)
        XCTAssertFalse(manager.isValidSearchEngineName(CUSTOM_ENGINE_NAME))
    }*/

    func testDisabledEngineIsNotValidSearchEngineName() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let engineToRemove = manager.engines[1]
        XCTAssertFalse(manager.isValidSearchEngineName(engineToRemove.name))
        manager.removeEngine(engine: engineToRemove)
        XCTAssertFalse(manager.isValidSearchEngineName(engineToRemove.name))
    }
    
    func testQueryFromSearchURLGoogle() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let url = URL(string: "https://www.google.com/search?q=ps5&source=hp&ei=yDybY7_iBMSH9u8P-fWwkAs&iflsig=AJiK0e8AAAAAY5tK2K2eVYMzMJI3G8qcqgmnGdrC6UVp&ved=0ahUKEwi_5s_h9_v7AhXEg_0HHfk6DLIQ4dUDCAg&uact=5&oq=ps5&gs_lcp=Cgdnd3Mtd2l6EAMyBQgAEIAEMgUIABCABDIFCAAQgAQyBQgAEIAEMgUIABCABDIICAAQgAQQyQMyBQgAEIAEMgUIABCABDIFCAAQgAQyBQgAEIAEOgsILhCABBDHARDRAzoFCC4QgAQ6CAguEIAEENQCUIoEWOwGYKIJaAFwAHgAgAFLiAHcAZIBATOYAQCgAQGwAQA&sclient=gws-wiz")
        guard let url = url else {
            XCTFail()
            return
        }
        XCTAssertEqual(manager.queryForSearchURL(url), "ps5")
    }

    func testQueryFromSearchURLAmazon() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let url = URL(string: "https://www.amazon.com/s?k=ps5&crid=PHPNYHV6UT42&sprefix=ps%2Caps%2C192&ref=nb_sb_noss_2")
        guard let url = url else {
            XCTFail()
            return
        }
        XCTAssertEqual(manager.queryForSearchURL(url), "ps5")
    }

    func testQueryFromSearchURLDuckDuckGo() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let url = URL(string: "https://duckduckgo.com/?q=ps5&t=h_&ia=web")
        guard let url = url else {
            XCTFail()
            return
        }
        XCTAssertEqual(manager.queryForSearchURL(url), "ps5")
    }
    
}

private class MockUserDefaults: UserDefaults {
    var setCalls = 0
    var valueCalls = 0

    func clear() {
        removeObject(forKey: SearchEngineManager.prefKeyEngine)
        removeObject(forKey: SearchEngineManager.prefKeyDisabledEngines)
        removeObject(forKey: SearchEngineManager.prefKeyCustomEngines)
        setCalls = 0
        valueCalls = 0
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        setCalls += 1
        super.set(value, forKey: defaultName)
    }

    override func value(forKey key: String) -> Any? {
        valueCalls += 1
        return super.value(forKey: key)
    }
}

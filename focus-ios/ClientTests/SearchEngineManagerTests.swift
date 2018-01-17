/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import XCTest
@testable import Firefox_Focus

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
        XCTAssertEqual(mockUserDefaults.setCalls, 3)
    }
    
    func testRemoveDefaultEngine() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let engineToRemove = manager.engines[1]
        manager.removeEngine(engine: engineToRemove)
        
        XCTAssertEqual(mockUserDefaults.setCalls, 2)
        XCTAssertFalse(manager.engines.contains(where: { (engine) -> Bool in
            return engine.name == engineToRemove.name
        }))
    }
    
    func testRemoveCustomEngine() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let engineAdded = manager.addEngine(name: CUSTOM_ENGINE_NAME, template: CUSTOM_ENGINE_TEMPLATE)
        manager.activeEngine = manager.engines[0]
        manager.removeEngine(engine: engineAdded)
        
        XCTAssertEqual(mockUserDefaults.setCalls, 5)
        XCTAssertFalse(manager.engines.contains(where: { (engine) -> Bool in
            return engine.name == engineAdded.name
        }))
    }
    
    func testResetDefaultEngines() {
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
        XCTAssertEqual(mockUserDefaults.setCalls, 1)
    }
    
    func testEmptyIsNotValidSearchEngineName() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        XCTAssertFalse(manager.isValidSearchEngineName(""))
    }
    
    func testCustomEngineIsNotValidSearchEngineName() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        XCTAssertTrue(manager.isValidSearchEngineName(CUSTOM_ENGINE_NAME))
        _ = manager.addEngine(name: CUSTOM_ENGINE_NAME, template: CUSTOM_ENGINE_TEMPLATE)
        XCTAssertFalse(manager.isValidSearchEngineName(CUSTOM_ENGINE_NAME))
    }
    
    func testDisabledEngineIsNotValidSearchEngineName() {
        let manager = SearchEngineManager(prefs: mockUserDefaults)
        let engineToRemove = manager.engines[1]
        XCTAssertFalse(manager.isValidSearchEngineName(engineToRemove.name))
        manager.removeEngine(engine: engineToRemove)
        XCTAssertFalse(manager.isValidSearchEngineName(engineToRemove.name))
    }
}

class MockUserDefaults: UserDefaults {
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

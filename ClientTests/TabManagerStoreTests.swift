/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Shared
import Storage
import UIKit
import WebKit
import Deferred

import XCTest



class TabManagerStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testTabsToRestoreWithNoData() {
        let manager = TabManagerStore(imageStore: nil)
        let result = manager.tabsToRestore(fromData: nil)
        XCTAssertEqual(result, nil)
    }

    func testTabsToRestoreWithData() {
        let manager = TabManagerStore(imageStore: nil)
        let dataSize = 3
        let data = SavedTab.generateDummyData(size: dataSize)
        let result = manager.tabsToRestore(fromData: data)
        XCTAssertEqual(result?.count, dataSize)
    }

    func testTabArchiveDataFileManagerCalled() {
        let mock = FileManagerMock()
        let manager = TabManagerStore(imageStore: nil, mock)
        let _ = manager.tabArchiveData()

        XCTAssertTrue(mock.fileExistsAtPathCalled)
    }

    func testPrepareSavedTabsEmptyTabArrayReturnNil() {
        let mock = FileManagerMock()
        let manager = TabManagerStore(imageStore: nil, mock)
        let tabs = [Tab]()
        let result = manager.prepareSavedTabs(fromTabs: tabs, selectedTab: nil)
        
        XCTAssertEqual(result, nil)
    }

    func testPrepareSavedTabsEmptyTabArrayReturnSavedTabs() {
        let mock = FileManagerMock()
        let manager = TabManagerStore(imageStore: nil, mock)
        let tabs = Tab.generateTabs(size: 3)
        let result = manager.prepareSavedTabs(fromTabs: tabs, selectedTab: nil)

        XCTAssertNotNil(result, "Expected to return SavedTabs")
        XCTAssertEqual(result?.count, tabs.count)
    }
    
    func testRestoreInternal() {
        let mock = FileManagerMock()
        let managerStore = TabManagerStore(imageStore: nil, mock)
        let profile = TabManagerMockProfile()
        let managerMock = TabManagerMock(prefs: profile.prefs, imageStore: nil)
        let savedTabsToRestore = SavedTab.generateDummySavedTabs(size: 3)

        let _ = managerStore.restoreInternal(savedTabs: savedTabsToRestore, clearPrivateTabs: false, tabManager: managerMock)
        XCTAssertEqual(managerMock.addTabCalledCounter, savedTabsToRestore.count)
    }
}

class FileManagerMock: FileManager {
    var fileExistsAtPathCalled: Bool = false

    override func fileExists(atPath path: String) -> Bool {
        fileExistsAtPathCalled = true
        return true
    }
}

class TabManagerMock: TabManager {
    var addTabCalledCounter: Int = 0
    override func addTab(_ request: URLRequest!, configuration: WKWebViewConfiguration!, afterTab: Tab?, isPrivate: Bool) -> Tab {
        addTabCalledCounter += 1
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        return Tab(configuration: configuration)
    }
    override func addTab(_ request: URLRequest? = nil, configuration: WKWebViewConfiguration? = nil, afterTab: Tab? = nil, flushToDisk: Bool, zombie: Bool, isPrivate: Bool = false) -> Tab {
        addTabCalledCounter += 1
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        return Tab(configuration: configuration)
    }

}

extension Tab {
    static func generateTabs(size: Int) -> [Tab] {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        
        var tabs = [Tab]()
        for _ in 0..<size {
            let tab = Tab(configuration: configuration)
            tab.sessionData = SessionData(currentPage: 0, urls: [URL(string: "url")!], lastUsedTime: Date.now())
            tabs.append(tab)
        }
        return tabs
    }
}

extension SavedTab {
    static func generateDummyData(size: Int, correctKey: Bool = true) -> Data? {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        
        let savedTabs = SavedTab.generateDummySavedTabs(size: size, correctKey: correctKey)
        
        let tabStateData = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: tabStateData)
        correctKey ? archiver.encode(savedTabs, forKey: "tabs") : archiver.encode(savedTabs, forKey: "incorrectKey")
        archiver.finishEncoding()
        
        return archiver.encodedData
    }
    static func generateDummySavedTabs(size: Int, correctKey: Bool = true) -> [SavedTab] {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        
        var savedTabs = [SavedTab]()
        for _ in 0..<size {
            let tab = Tab(configuration: configuration)
            tab.sessionData = SessionData(currentPage: 0, urls: [URL(string: "url")!], lastUsedTime: Date.now())
            if let savedTab = SavedTab(tab: tab, isSelected: false) {
                savedTabs.append(savedTab)
            }
        }
        
        return savedTabs
    }
}

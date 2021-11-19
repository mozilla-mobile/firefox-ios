// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import WebKit
import Shared
import XCTest

class TabDisplayManagerTests: XCTestCase {

    var tabCellIdentifer: TabDisplayer.TabCellIdentifer = TopTabCell.Identifier

    var mockDataStore = WeakListMock<Tab>()
    var dataStore = WeakList<Tab>()
    var collectionView: MockCollectionView!
    var profile: TabManagerMockProfile!
    var manager: TabManager!

    override func setUp() {
        super.setUp()

        profile = TabManagerMockProfile()
        manager = TabManager(profile: profile, imageStore: nil)
        collectionView = MockCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        manager.removeAll()
        manager.testClearArchive()
        profile = nil
        manager = nil
        collectionView = nil
        dataStore.removeAll()
        mockDataStore.removeAll()
    }

    // MARK: Index to place tab

    func testIndexToPlaceTab_countAtZero_placeAtZero() {
        mockDataStore.countToReturn = 0
        let tabDisplayManager = createTabDisplayManager()
        let index = tabDisplayManager.getIndexToPlaceTab(placeNextToParentTab: false)

        XCTAssertEqual(index, 0)
    }

    func testIndexToPlaceTab_countAtOne_placeAtOne() {
        mockDataStore.countToReturn = 1
        let tabDisplayManager = createTabDisplayManager()
        let index = tabDisplayManager.getIndexToPlaceTab(placeNextToParentTab: false)

        XCTAssertEqual(index, 1)
    }

    func testIndexToPlaceTab_countAtTwo_placeAtTwo() {
        mockDataStore.countToReturn = 2
        let tabDisplayManager = createTabDisplayManager()
        let index = tabDisplayManager.getIndexToPlaceTab(placeNextToParentTab: false)

        XCTAssertEqual(index, 2)
    }

    func testIndexToPlaceTab_countAtMinusOne_placeAtZero() {
        mockDataStore.countToReturn = -1
        let tabDisplayManager = createTabDisplayManager()
        let index = tabDisplayManager.getIndexToPlaceTab(placeNextToParentTab: false)

        XCTAssertEqual(index, 0)
    }

    func testIndexToPlaceTab_hasOneTab_newTabAtIndex1() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add one tab
        let selectedTab = manager.addTab()
        manager.selectTab(selectedTab)
        XCTAssertEqual(tabDisplayManager.dataStore.count, 1)

        // Add new tab
        let newTab = manager.addTab()

        XCTAssertEqual(tabDisplayManager.dataStore.count, 2)
        XCTAssertEqual(manager.tabs[1].tabUUID, newTab.tabUUID, "New tab should be placed at last position, at index 1")
        XCTAssertEqual(tabDisplayManager.dataStore.at(1)?.tabUUID, newTab.tabUUID, "New tab should be placed at last position, at index 1")
    }

    func testIndexToPlaceTab_hasThreeTabsLastSelected_newTabAtIndex3() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add three tab
        manager.addTab()
        manager.addTab()
        let selectedTab = manager.addTab()
        manager.selectTab(selectedTab)
        XCTAssertEqual(tabDisplayManager.dataStore.count, 3)

        // Add new tab
        let newTab = manager.addTab()

        XCTAssertEqual(tabDisplayManager.dataStore.count, 4)
        XCTAssertEqual(manager.tabs[3].tabUUID, newTab.tabUUID, "New tab should be placed at last position, at index 3")
        XCTAssertEqual(tabDisplayManager.dataStore.at(3)?.tabUUID, newTab.tabUUID, "New tab should be placed at last position, at index 3")
    }

    func testIndexToPlaceTab_hasThreeTabsFirstSelected_newTabAtIndex3() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add three tab
        manager.addTab()
        manager.addTab()
        let selectedTab = manager.addTab()
        manager.selectTab(selectedTab)
        XCTAssertEqual(tabDisplayManager.dataStore.count, 3)

        // Add new tab
        let newTab = manager.addTab()

        XCTAssertEqual(tabDisplayManager.dataStore.count, 4)
        XCTAssertEqual(manager.tabs[3].tabUUID, newTab.tabUUID, "New tab should be placed at last position, at index 3")
        XCTAssertEqual(tabDisplayManager.dataStore.at(3)?.tabUUID, newTab.tabUUID, "New tab should be placed at last position, at index 3")
    }

    // MARK: Place tab next to parent tab

    func testPlaceNextToParentTab_parentWasLastTab_newTabPlaceIsLast() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add three tabs with parent at last position
        manager.addTab()
        manager.addTab()
        let parentTab = manager.addTab()
        manager.selectTab(parentTab)
        XCTAssertEqual(tabDisplayManager.dataStore.count, 3)

        // Add child tab after parent
        let childTab = manager.addTab(afterTab: parentTab)

        XCTAssertEqual(tabDisplayManager.dataStore.count, 4)
        XCTAssertEqual(manager.tabs[3].tabUUID, childTab.tabUUID, "Child tab should be placed after the parent tab, at index 3")
        XCTAssertEqual(tabDisplayManager.dataStore.at(3)?.tabUUID, childTab.tabUUID, "Child tab should be placed after the parent tab, at index 3")
    }

    func testPlaceNextToParentTab_parentWasNotLastTab_newTabPlaceIsAfterParent() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add three tabs with parent at second position, not last
        manager.addTab()
        let parentTab = manager.addTab()
        manager.addTab()
        manager.selectTab(parentTab)
        XCTAssertEqual(tabDisplayManager.dataStore.count, 3)

        // Add child tab after parent
        let childTab = manager.addTab(afterTab: parentTab)

        XCTAssertEqual(tabDisplayManager.dataStore.count, 4)
        XCTAssertEqual(manager.tabs[2].tabUUID, childTab.tabUUID, "Child tab should be placed after the parent tab, at index 2")
        XCTAssertEqual(tabDisplayManager.dataStore.at(2)?.tabUUID, childTab.tabUUID, "Child tab should be placed after the parent tab, at index 2")
    }

    func testPlaceNextToParentTab_parentWasFirstTab_newTabPlaceIsAfterParent() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add three tabs with parent at first position
        let parentTab = manager.addTab()
        manager.addTab()
        manager.addTab()
        manager.selectTab(parentTab)
        XCTAssertEqual(tabDisplayManager.dataStore.count, 3)

        // Add child tab after parent
        let childTab = manager.addTab(afterTab: parentTab)

        XCTAssertEqual(tabDisplayManager.dataStore.count, 4)
        XCTAssertEqual(manager.tabs[1].tabUUID, childTab.tabUUID, "Child tab should be placed after the parent tab, at index 1")
        XCTAssertEqual(tabDisplayManager.dataStore.at(1)?.tabUUID, childTab.tabUUID, "Child tab should be placed after the parent tab, at index 1")
    }
}

// Helper methods
extension TabDisplayManagerTests {

    func createTabDisplayManager(useMockDataStore: Bool = true) -> TabDisplayManager {
        let tabDisplayManager = TabDisplayManager(collectionView: collectionView,
                                                  tabManager: manager,
                                                  tabDisplayer: self,
                                                  reuseID: TopTabCell.Identifier,
                                                  tabDisplayType: .TopTabTray,
                                                  profile: profile)
        collectionView.dataSource = tabDisplayManager
        tabDisplayManager.dataStore = useMockDataStore ? mockDataStore : dataStore
        return tabDisplayManager
    }
}

extension TabDisplayManagerTests: TabDisplayer {

    func focusSelectedTab() {}

    func cellFactory(for cell: UICollectionViewCell, using tab: Tab) -> UICollectionViewCell {
        guard let tabCell = cell as? TopTabCell else { return UICollectionViewCell() }
        let isSelected = (tab == manager.selectedTab)
        tabCell.configureWith(tab: tab, isSelected: isSelected)
        tabCell.applyTheme()
        return tabCell
    }
}

class WeakListMock<T: AnyObject>: WeakList<T> {

    var countToReturn: Int = 0
    override var count: Int {
        return countToReturn
    }
}

class MockCollectionView: UICollectionView {

    override init(frame: CGRect, collectionViewLayout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: collectionViewLayout)

        register(TopTabCell.self, forCellWithReuseIdentifier: TopTabCell.Identifier)
        register(InactiveTabCell.self, forCellWithReuseIdentifier: InactiveTabCell.Identifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        updates?()
        completion?(true)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import WebKit
import Shared
import XCTest
import Common

class TabDisplayManagerTests: XCTestCase {
    var tabCellIdentifier: TabDisplayerDelegate.TabCellIdentifier = TopTabCell.cellIdentifier

    var mockDataStore: WeakListMock<Tab>!
    var dataStore: WeakList<Tab>!
    var collectionView: MockCollectionView!
    var profile: TabManagerMockProfile!
    var manager: TabManager!
    var cfrDelegate: MockInactiveTabsCFRDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockDataStore = WeakListMock<Tab>()
        dataStore = WeakList<Tab>()
        profile = TabManagerMockProfile(databasePrefix: "TabDisplayManagerTests") // not using the default prefix to avoid side effects with other tests
        manager = LegacyTabManager(profile: profile, imageStore: nil)
        collectionView = MockCollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        cfrDelegate = MockInactiveTabsCFRDelegate()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        UserDefaults().setValue(true, forKey: PrefsKeys.KeyInactiveTabsFirstTimeRun)
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
        profile.shutdown()
        manager.testRemoveAll()
        manager.testClearArchive()
        profile = nil
        manager = nil
        collectionView = nil
        cfrDelegate = nil

        dataStore.removeAll()
        mockDataStore.removeAll()
        mockDataStore = nil
        dataStore = nil
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

    // MARK: Selected cell

    func testSelectedCell_lastTabSelectedAndRemoved() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add four tabs with selected at last position
        manager.addTab()
        manager.addTab()
        manager.addTab()
        let selectedTab = manager.addTab()
        manager.selectTab(selectedTab)

        removeTabAndAssert(tab: selectedTab) {
            // Should be selected tab is index 2, and no other one is selected
            self.testSelectedCells(tabDisplayManager: tabDisplayManager, numberOfCells: 3, selectedIndex: 2)
        }
    }

    func testSelectedCell_secondToLastTabSelectedAndRemoved() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add four tabs with selected at second to last position
        manager.addTab()
        manager.addTab()
        let selectedTab = manager.addTab()
        manager.addTab()
        manager.selectTab(selectedTab)

        // Remove selected
        removeTabAndAssert(tab: selectedTab) {
            // Should be selected tab is index 1, and no other one is selected
            self.testSelectedCells(tabDisplayManager: tabDisplayManager, numberOfCells: 3, selectedIndex: 2)
        }
    }

    func testSelectedCell_secondToLastTabSelectedAndTabBeforeRemoved() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)

        // Add four tabs with selected at second to last position
        manager.addTab()
        let tabToRemove = manager.addTab()
        let selectedTab = manager.addTab()
        manager.addTab()
        manager.selectTab(selectedTab)

        // Remove second tab
        removeTabAndAssert(tab: tabToRemove) {
            // Should be selected tab is index 1, and no other one is selected
            self.testSelectedCells(tabDisplayManager: tabDisplayManager, numberOfCells: 3, selectedIndex: 1)
        }
    }

    // MARK: Inactive Tabs
    func testInactiveTabs_iPad_hiddenInTopTabs() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TopTabTray

        // Add four tabs (2 inactive, 2 active)
        let inactiveTab1 = manager.addTab()
        inactiveTab1.lastExecutedTime = Date().older.toTimestamp()
        let inactiveTab2 = manager.addTab()
        inactiveTab2.lastExecutedTime = Date().older.toTimestamp()
        let activeTab1 = manager.addTab()
        _ = manager.addTab()
        manager.selectTab(activeTab1)

        let expectation = self.expectation(description: "TabDisplayManagerTests")
        tabDisplayManager.refreshStore {
            XCTAssertEqual(tabDisplayManager.filteredTabs.count, 2, "Only 2 active tabs should be displayed")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testInactiveTabs_grid_singleInactiveTabShowAsActive() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid

        // Add 1 inactive tab
        let inactiveTab1 = manager.addTab()
        inactiveTab1.lastExecutedTime = Date().older.toTimestamp()

        let expectation = self.expectation(description: "TabDisplayManagerTests")
        tabDisplayManager.refreshStore {
            XCTAssertEqual(tabDisplayManager.filteredTabs.count, 1, "1 active tabs should be displayed")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testInactiveTabs_grid_filterInactive() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid

        // Add four tabs (2 inactive, 2 active)
        let inactiveTab1 = manager.addTab()
        inactiveTab1.lastExecutedTime = Date().older.toTimestamp()
        let inactiveTab2 = manager.addTab()
        inactiveTab2.lastExecutedTime = Date().older.toTimestamp()
        let activeTab1 = manager.addTab()
        _ = manager.addTab()
        manager.selectTab(activeTab1)

        let expectation = self.expectation(description: "TabDisplayManagerTests")
        tabDisplayManager.refreshStore {
            XCTAssertEqual(tabDisplayManager.filteredTabs.count, 2, "Only 2 active tabs should be displayed")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testInactiveTabs_grid_closeTabs() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid
        tabDisplayManager.inactiveViewModel = InactiveTabViewModel(theme: LightTheme())

        // Add four tabs (2 inactive, 2 active)
        let inactiveTab1 = manager.addTab()
        inactiveTab1.lastExecutedTime = Date().older.toTimestamp()
        let inactiveTab2 = manager.addTab()
        inactiveTab2.lastExecutedTime = Date().older.toTimestamp()
        let activeTab1 = manager.addTab()
        _ = manager.addTab()
        manager.selectTab(activeTab1)

        tabDisplayManager.inactiveViewModel?.inactiveTabs = [inactiveTab1,
                                                             inactiveTab2]

        // Force collectionView reload section to avoid crash
        cfrDelegate.isUndoButtonPressed = false
        // Force collectionView reload to avoid crash
        collectionView.reloadSections(IndexSet(integer: 0))
        tabDisplayManager.didTapCloseInactiveTabs(tabsCount: 2)

        // For delete all inactive tabs we don't actually delete the tabs we collapse
        // the section and delete after toast delay
        XCTAssertTrue(tabDisplayManager.inactiveViewModel?.shouldHideInactiveTabs ?? false, "Inactive tabs should be empty after closing")
    }

    func testInactiveTabs_grid_undoSingleTab() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid
        tabDisplayManager.inactiveViewModel = InactiveTabViewModel(theme: LightTheme())

        // Add three tabs (2 inactive, 1 active)
        let inactiveTab1 = manager.addTab()
        inactiveTab1.lastExecutedTime = Date().older.toTimestamp()
        let inactiveTab2 = manager.addTab()
        inactiveTab2.lastExecutedTime = Date().older.toTimestamp()
        let activeTab1 = manager.addTab()
        manager.selectTab(activeTab1)

        tabDisplayManager.inactiveViewModel?.inactiveTabs = [inactiveTab1,
                                                             inactiveTab2]
        // Force collectionView reload section to avoid crash
        collectionView.reloadSections(IndexSet(integer: 0))
        cfrDelegate.isUndoButtonPressed = true
        // Force collectionView reload to avoid crash
        collectionView.reloadSections(IndexSet(integer: 0))
        tabDisplayManager.closeInactiveTab(inactiveTab1, index: 0)

        let expectation = self.expectation(description: "TabDisplayManagerTests")
        tabDisplayManager.refreshStore {
            XCTAssertEqual(tabDisplayManager.inactiveViewModel?.inactiveTabs.count, 2, "Expected 2 inactive tabs after undo")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testInactiveTabs_grid_closeSingleTab() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid
        tabDisplayManager.inactiveViewModel = InactiveTabViewModel(theme: LightTheme())

        // Add three tabs (2 inactive, 1 active)
        let inactiveTab1 = manager.addTab()
        inactiveTab1.lastExecutedTime = Date().older.toTimestamp()
        let inactiveTab2 = manager.addTab()
        inactiveTab2.lastExecutedTime = Date().older.toTimestamp()
        let activeTab1 = manager.addTab()
        manager.selectTab(activeTab1)

        tabDisplayManager.inactiveViewModel?.inactiveTabs = [inactiveTab1,
                                                             inactiveTab2]
        // Force collectionView reload section to avoid crash
        collectionView.reloadSections(IndexSet(integer: 0))
        cfrDelegate.isUndoButtonPressed = false
        // Force collectionView reload to avoid crash
        collectionView.reloadSections(IndexSet(integer: 0))
        tabDisplayManager.closeInactiveTab(inactiveTab1, index: 0)

        let expectation = self.expectation(description: "TabDisplayManagerTests")
        // Add delay so the tab removal finishes and the refreshStore gets the right tabs data
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            tabDisplayManager.refreshStore {
                XCTAssertEqual(tabDisplayManager.inactiveViewModel?.inactiveTabs.count, 1, "Expected 1 inactive tab after deletion")
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 5)
    }

    func testInactiveTabs_grid_undoCloseTabs() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid
        tabDisplayManager.inactiveViewModel = InactiveTabViewModel(theme: LightTheme())

        // Add four tabs (2 inactive, 2 active)
        let inactiveTab1 = manager.addTab()
        inactiveTab1.lastExecutedTime = Date().older.toTimestamp()
        let inactiveTab2 = manager.addTab()
        inactiveTab2.lastExecutedTime = Date().older.toTimestamp()
        let activeTab1 = manager.addTab()
        _ = manager.addTab()
        manager.selectTab(activeTab1)

        tabDisplayManager.inactiveViewModel?.inactiveTabs = [inactiveTab1,
                                                             inactiveTab2]

        // Force collectionView reload section to avoid crash
        collectionView.reloadSections(IndexSet(integer: 0))
        cfrDelegate.isUndoButtonPressed = true
        // Force collectionView reload to avoid crash
        collectionView.reloadSections(IndexSet(integer: 0))
        tabDisplayManager.didTapCloseInactiveTabs(tabsCount: 2)

        let expectation = self.expectation(description: "TabDisplayManagerTests")
        tabDisplayManager.refreshStore {
            XCTAssertEqual(tabDisplayManager.inactiveViewModel?.inactiveTabs.count, 2, "Expected 2 inactive tabs after undo")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    // MARK: - Undo tab close
    func testShouldPresentUndoToastOnHomepage_ForLastTab() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid
        manager.addTab()

        XCTAssertTrue(tabDisplayManager.shouldPresentUndoToastOnHomepage,
                      "Expected to present toast on homepage")
    }

    func testShouldNotPresentUndoToastOnHomepage_MultlipleTabs() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid

        // Add 2 tabs
        let activeTab1 = manager.addTab()
        _ = manager.addTab()
        manager.selectTab(activeTab1)

        XCTAssertFalse(tabDisplayManager.shouldPresentUndoToastOnHomepage,
                       "Expected to present toast on TabTray")
    }

    func testShouldNotPresentUndoToastOnHomepage_ForLastPrivateTab() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid

        _ = manager.addTab(nil, afterTab: nil, isPrivate: true)

        XCTAssertFalse(tabDisplayManager.shouldPresentUndoToastOnHomepage,
                       "Expected to present toast on TabTray")
    }

    func testShouldNotPresentUndoToastOnHomepage_ForMultiplePrivateTabs() {
        let tabDisplayManager = createTabDisplayManager(useMockDataStore: false)
        tabDisplayManager.tabDisplayType = .TabGrid

        // Add 2 tabs
        let activeTab1 = manager.addTab(nil, afterTab: nil, isPrivate: true)
        _ = manager.addTab(nil, afterTab: nil, isPrivate: true)
        manager.selectTab(activeTab1)

        XCTAssertFalse(tabDisplayManager.shouldPresentUndoToastOnHomepage,
                       "Expected to present toast on TabTray")
    }

    func testInitWithExistingRegularTabs() {
        let tabDisplayManager = createTabDisplayManagerWithTabs(amountOfTabs: 3, isPrivate: false)
        tabDisplayManager.tabDisplayType = .TabGrid

        XCTAssertEqual(manager.normalTabs.count, 3, "Expected 3 tabs")
    }

    func testInitWithExistingPrivateTabs() {
        let tabDisplayManager = createTabDisplayManagerWithTabs(amountOfTabs: 3, isPrivate: true)
        tabDisplayManager.tabDisplayType = .TabGrid

        XCTAssertEqual(manager.privateTabs.count, 3, "Expected 3 tabs")
    }

    func testTabDisplayManager_doesntLeak() {
        let subject = createTabDisplayManager(useMockDataStore: false)
        trackForMemoryLeaks(subject)
    }
}

// Helper methods
extension TabDisplayManagerTests {
    func removeTabAndAssert(tab: Tab, completion: @escaping () -> Void) {
        let expectation = self.expectation(description: "Tab is removed")
        manager.removeTab(tab) {
            completion()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func createTabDisplayManager(file: StaticString = #file,
                                 line: UInt = #line,
                                 useMockDataStore: Bool = true) -> TabDisplayManager {
        let tabDisplayManager = TabDisplayManager(collectionView: collectionView,
                                                  tabManager: manager,
                                                  tabDisplayer: self,
                                                  reuseID: TopTabCell.cellIdentifier,
                                                  tabDisplayType: .TopTabTray,
                                                  profile: profile,
                                                  cfrDelegate: cfrDelegate,
                                                  theme: LightTheme())
        collectionView.dataSource = tabDisplayManager
        tabDisplayManager.dataStore = useMockDataStore ? mockDataStore : dataStore
        trackForMemoryLeaks(tabDisplayManager, file: file, line: line)
        return tabDisplayManager
    }

    func createTabDisplayManagerWithTabs(amountOfTabs: Int, isPrivate: Bool) -> TabDisplayManager {
        for _ in 0..<amountOfTabs {
            _ = manager.addTab(nil, afterTab: nil, isPrivate: isPrivate)
        }

        let tabDisplayManager = TabDisplayManager(collectionView: collectionView,
                                                  tabManager: manager,
                                                  tabDisplayer: self,
                                                  reuseID: TopTabCell.cellIdentifier,
                                                  tabDisplayType: .TopTabTray,
                                                  profile: profile,
                                                  cfrDelegate: cfrDelegate,
                                                  theme: LightTheme())
        collectionView.dataSource = tabDisplayManager
        trackForMemoryLeaks(tabDisplayManager)
        return tabDisplayManager
    }

    func testSelectedCells(tabDisplayManager: TabDisplayManager, numberOfCells: Int, selectedIndex: Int, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(tabDisplayManager.dataStore.count, numberOfCells, file: file, line: line)
        for index in 0..<numberOfCells {
            let cell = tabDisplayManager.collectionView(collectionView, cellForItemAt: IndexPath(row: index, section: 0)) as! TabTrayCell
            if index == selectedIndex {
                XCTAssertTrue(cell.isSelectedTab, file: file, line: line)
            } else {
                XCTAssertFalse(cell.isSelectedTab, file: file, line: line)
            }
        }
    }
}

extension TabDisplayManagerTests: TabDisplayerDelegate {
    func focusSelectedTab() {}

    func cellFactory(for cell: UICollectionViewCell, using tab: Tab) -> UICollectionViewCell {
        guard let tabCell = cell as? TabTrayCell else { return UICollectionViewCell() }
        let isSelected = (tab == manager.selectedTab)
        tabCell.configureWith(tab: tab, isSelected: isSelected, theme: LightTheme())
        return tabCell
    }
}

class WeakListMock<T: AnyObject>: WeakList<T> {
    var countToReturn: Int = 0
    override var count: Int {
        return countToReturn
    }

    override var isEmpty: Bool {
        return countToReturn <= 0
    }
}

class MockCollectionView: UICollectionView {
    override init(frame: CGRect, collectionViewLayout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: collectionViewLayout)

        register(TopTabCell.self, forCellWithReuseIdentifier: TopTabCell.cellIdentifier)
        register(InactiveTabCell.self, forCellWithReuseIdentifier: InactiveTabCell.cellIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        updates?()
        completion?(true)
    }

    /// Due to the usage of MockCollectionView with the overridden performBatchUpdates in prod code for those tests, deleteItems needs an extra check.
    /// No check was added for prod code so it would crash in case of concurrency (which would be abnormal and need to be detected)
    override func deleteItems(at indexPaths: [IndexPath]) {
        guard indexPaths[0].row <= numberOfItems(inSection: 0) - 1 else { return }
        super.deleteItems(at: indexPaths)
    }
}

class MockInactiveTabsCFRDelegate: InactiveTabsCFRProtocol {
    var isUndoButtonPressed = true

    func setupCFR(with view: UILabel) { }
    func presentCFR() { }

    func presentUndoToast(tabsCount: Int, completion: @escaping (Bool) -> Void) {
        completion(isUndoButtonPressed)
    }

    func presentUndoSingleToast(completion: @escaping (Bool) -> Void) {
        completion(isUndoButtonPressed)
    }
}

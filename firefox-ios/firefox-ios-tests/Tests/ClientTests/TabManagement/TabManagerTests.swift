// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import WebKit
import Shared
import Common
@testable import Client

// Note: Some of these tests are annotated with @MainActor because a new Tab is created without the zombie flag set to true.
// This is unavoidable with the current architecture given a new tab is created as a side effect. For these tabs, if the test
// isn't run on the main thread, then in its deinit the webView.navigationDelegate is updated not on the main thread, causing
// failures in Bitrise. This should be improved. [FXIOS-10110]
class TabManagerTests: XCTestCase {
    var tabWindowUUID: WindowUUID!
    var mockTabStore: MockTabDataStore!
    var mockSessionStore: MockTabSessionStore!
    var mockProfile: MockProfile!
    var mockDiskImageStore: MockDiskImageStore!
    let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()

        // Disable debug flag for faster inactive tabs and perform tests based on the real 14 day time to inactive
        UserDefaults.standard.set(nil, forKey: PrefsKeys.FasterInactiveTabsOverride)

        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        // For this test suite, use a consistent window UUID for all test cases
        let uuid: WindowUUID = .XCTestDefaultUUID
        tabWindowUUID = uuid

        mockProfile = MockProfile()
        mockDiskImageStore = MockDiskImageStore()
        mockTabStore = MockTabDataStore()
        mockSessionStore = MockTabSessionStore()
        setIsDeeplinkOptimizationRefactorEnabled(false)
        setIsPDFRefactorEnabled(false)
    }

    override func tearDown() {
        mockProfile = nil
        mockDiskImageStore = nil
        mockTabStore = nil
        mockSessionStore = nil
        super.tearDown()
    }

    func testRecentlyAccessedNormalTabs() {
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .normalInactive, count: 2))
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 2))
        let subject = createSubject(tabs: tabs)
        let normalActiveTabs = subject.recentlyAccessedNormalTabs
        XCTAssertEqual(normalActiveTabs.count, 5)
        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
        let normalTabs = subject.recentlyAccessedNormalTabs
        XCTAssertEqual(normalTabs.count, 7)
        UserDefaults.standard.removeObject(forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
    }

    func testTabIndexSubscript() {
        let subject = createSubject(tabs: generateTabs(count: 5))
        let tab = subject[0]
        XCTAssertNotNil(tab)
    }

    func testRemoveTabs() {
        let subject = createSubject(tabs: generateTabs(count: 5))
        let tabs = subject.tabs
        subject.removeTabs(tabs)
        XCTAssertEqual(subject.tabs.count, 0)
    }

    func testRemoveTabsByURLs() async {
        let subject = createSubject(tabs: generateTabs(count: 5))
        await subject.removeTabs(by: [URL(string: "https://mozilla.com?item=4")!, URL(string: "https://mozilla.com?item=1")!])
        let remainingURLs = subject.tabs.compactMap { $0.url?.absoluteString }
        XCTAssertEqual(remainingURLs, ["https://mozilla.com?item=0", "https://mozilla.com?item=2", "https://mozilla.com?item=3"])
    }

    func testRemoveAllTabsForPrivateMode() async {
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 4))
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.tabs.count, 9)
        await subject.removeAllTabs(isPrivateMode: true)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    // This test has to be run on the main thread since we are messing with the WebView.
    @MainActor
    func testRemoveAllTabsCallsSaveTabSession() async {
        let subject = createSubject()
        _ = subject.addTab(URLRequest(url: URL(string: "https://mozilla.com")!), afterTab: nil, isPrivate: false)
        await subject.removeAllTabs(isPrivateMode: false)

        XCTAssertEqual(mockSessionStore.saveTabSessionCallCount, 1)
    }

    func testRemoveAllTabsForNotPrivateMode() async {
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 4))
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.tabs.count, 9)
        await subject.removeAllTabs(isPrivateMode: false)
        XCTAssertEqual(subject.tabs.count, 4)
    }

    func testGetTabForUUID() {
        let subject = createSubject(tabs: generateTabs(count: 1))
        let uuid = subject.tabs.first!.tabUUID
        let tab = subject.getTabForUUID(uuid: uuid)
        XCTAssertEqual(tab, subject.tabs.first)
    }

    // This test has to be run on the main thread since we are messing with the WebView.
    @MainActor
    func testGetTabForURL() {
        let subject = createSubject()
        let addedTab = subject.addTab(URLRequest(url: URL(string: "https://mozilla.com")!), afterTab: nil, isPrivate: false)
        let tab = subject.getTabForURL(URL(string: "https://mozilla.com/")!)
        XCTAssertEqual(tab, addedTab)
    }

    func testGetMostRecentHomepageTab() {
        let tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        tab.url = URL(string: "\(InternalURL.baseUrl)/about/home#panel=0")!
        let subject = createSubject(tabs: [tab])
        let homeTab = subject.getMostRecentHomepageTab()
        XCTAssertEqual(tab, homeTab)
    }

    func testUndoCloseTab() {
        let subject = createSubject()
        let tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        tab.url = URL(string: "https://mozilla.com/")!
        XCTAssertEqual(subject.selectedIndex, -1)
        subject.backupCloseTab = BackupCloseTab(tab: tab, isSelected: true)
        subject.undoCloseTab()
        XCTAssertEqual(subject.selectedIndex, 0)
    }

    func testUndoCloseTabWithSelectedTab() {
        let closedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        closedTab.url = URL(string: "https://mozilla.com/")!
        let selectedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        selectedTab.url = URL(string: "https://mozilla.com/1")!
        let subject = createSubject(tabs: [selectedTab])
        subject.selectTab(selectedTab)
        XCTAssertEqual(subject.selectedIndex, 0)
        subject.backupCloseTab = BackupCloseTab(tab: closedTab, isSelected: true)
        subject.undoCloseTab()
        XCTAssertEqual(subject.selectedIndex, 1)
    }

    // MARK: - Document pause - restore

    func testSelectTab_pauseCurrentDocumentDownload() throws {
        setIsPDFRefactorEnabled(true)

        let tabs = generateTabs(count: 2)
        let document = MockTemporaryDocument(withFileURL: URL(string: "https://www.example.com")!)
        let subject = createSubject(tabs: tabs)

        let tab = try XCTUnwrap(tabs.first)
        tab.enqueueDocument(document)

        subject.selectTab(tabs[1], previous: tab)

        XCTAssertEqual(document.pauseResumeDownloadCalled, 1)
    }

    // MARK: - Restore tabs

    @MainActor
    func testRestoreTabs() {
        // Needed to ensure AppEventQueue is not fired from a previous test case with the same WindowUUID
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 4))

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            XCTAssertEqual(subject.tabs.count, 4)
            XCTAssertEqual(self.mockTabStore.fetchWindowDataCalledCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabsForced() {
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        let subject = createSubject(tabs: generateTabs(count: 5), windowUUID: testUUID)

        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 3))
        subject.restoreTabs(true)

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            XCTAssertEqual(subject.tabs.count, 3)
            XCTAssertEqual(self.mockTabStore.fetchWindowDataCalledCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabPresent_withSameURLAsRestoredTab() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        let tabs = generateTabs(count: 1)
        let deeplinkTab = try XCTUnwrap(tabs.first)
        let subject = createSubject(tabs: tabs, windowUUID: testUUID)
        let tabData = getMockTabData(count: 4)
        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: tabData
        )

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            // Tabs count has to be same as restoration data, since deeplink tab has same of URL of a restored tab.
            XCTAssertEqual(subject.tabs.count, tabData.count)
            XCTAssertEqual(subject.selectedTab, deeplinkTab)
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabNil_selectsPreviousSelectedTabData() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)

        let tabData = getMockTabData(count: 4)
        let previouslySelectedTabData = try XCTUnwrap(tabData.last)
        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: previouslySelectedTabData.id,
            tabData: tabData
        )

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            XCTAssertEqual(subject.tabs.count, tabData.count)
            XCTAssertEqual(subject.selectedTab?.tabUUID, previouslySelectedTabData.id.uuidString)
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabNotNil_selectsDeeplinkTab() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        let deeplinkTab = Tab(profile: mockProfile, windowUUID: testUUID)
        let subject = createSubject(tabs: [deeplinkTab], windowUUID: testUUID)

        let tabData = getMockTabData(count: 4)
        let previouslySelectedTabData = try XCTUnwrap(tabData.last)
        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: previouslySelectedTabData.id,
            tabData: tabData
        )

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            XCTAssertEqual(subject.tabs.count, tabData.count + 1)
            XCTAssertEqual(subject.selectedTab, deeplinkTab)
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    @MainActor
    func testRestoreTabs_whenDeeplinkTabPresent() {
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        setIsDeeplinkOptimizationRefactorEnabled(true)
        // Simulate deeplink tab
        let tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        tab.url = URL(string: "https://example.com")
        let subject = createSubject(tabs: [tab], windowUUID: testUUID)

        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: getMockTabData(count: 4)
        )

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            // Tabs count has to be the sum of deeplink and restored tabs, since the deeplink tab is not present in
            // the restored once.
            XCTAssertEqual(subject.tabs.count, 5)
            expectation.fulfill()
        }

        subject.restoreTabs()
        wait(for: [expectation])
    }

    func testRestoreTabs_whenDeeplinkTabPresent_doesnAddDepplinkTabMultipleTimes() throws {
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        let testUUID = UUID()
        setIsDeeplinkOptimizationRefactorEnabled(true)
        // Simulate deeplink tab
        let deeplinkTabData = try XCTUnwrap(getMockTabData(count: 1).first)
        let deeplinkTab = Tab(profile: mockProfile, windowUUID: testUUID)
        deeplinkTab.url = URL(string: deeplinkTabData.siteUrl)
        deeplinkTab.tabUUID = deeplinkTabData.id.uuidString
        let subject = createSubject(tabs: [deeplinkTab], windowUUID: testUUID)

        mockTabStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: getMockTabData(count: 4)
        )

        AppEventQueue.wait(for: .tabRestoration(testUUID)) {
            let filteredTabs = subject.tabs.filter {
                $0.tabUUID == deeplinkTab.tabUUID
            }
            // There has to be only one tab present
            XCTAssertEqual(filteredTabs.count, 1)
            expectation.fulfill()
        }

        subject.restoreTabs()
        wait(for: [expectation])
    }

    // MARK: - Save tabs

    func testPreserveTabsWithNoTabs() async throws {
        let subject = createSubject()
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 0)
        XCTAssertEqual(subject.tabs.count, 0)
    }

    func testPreserveTabsWithOneTab() async throws {
        let subject = createSubject(tabs: generateTabs(count: 1))
        subject.tabRestoreHasFinished = true
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(subject.tabs.count, 1)
    }

    func testPreserveTabsWithManyTabs() async throws {
        let subject = createSubject(tabs: generateTabs(count: 5))
        subject.tabRestoreHasFinished = true
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    // MARK: - Save preview screenshot

    func testSaveScreenshotWithNoImage() async throws {
        let subject = createSubject(tabs: generateTabs(count: 5))
        guard let tab = subject.tabs.first else {
            XCTFail("First tab was expected to be found")
            return
        }

        subject.tabDidSetScreenshot(tab)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockDiskImageStore.saveImageForKeyCallCount, 0)
    }

    func testSaveScreenshotWithImage() async throws {
        let subject = createSubject(tabs: generateTabs(count: 5))
        guard let tab = subject.tabs.first else {
            XCTFail("First tab was expected to be found")
            return
        }
        tab.setScreenshot(UIImage())
        subject.tabDidSetScreenshot(tab)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockDiskImageStore.saveImageForKeyCallCount, 1)
    }

    func testGetActiveAndInactiveTabs() {
        let totalTabCount = 3
        let subject = createSubject(tabs: generateTabs(count: totalTabCount))

        // Preconditions
        XCTAssertEqual(subject.tabs.count, totalTabCount, "Expected 3 newly added tabs.")
        XCTAssertEqual(subject.normalActiveTabs.count, totalTabCount, "All tabs should be active on initialization")

        // Override lastExecutedTime of 1st tab to be recent (i.e. active)
        // and lastExecutedTime of other 2 to be distant past (i.e. inactive)
        let lastExecutedDate = Calendar.current.add(numberOfDays: 1, to: Date())!
        subject.tabs[0].lastExecutedTime = lastExecutedDate.toTimestamp()
        subject.tabs[1].lastExecutedTime = 0
        subject.tabs[2].lastExecutedTime = 0

        // Test
        XCTAssertEqual(subject.normalActiveTabs.count, 1, "Only one tab remains active")
        XCTAssertEqual(subject.inactiveTabs.count, 2, "Two tabs should now be inactive")
        XCTAssertEqual(subject.normalTabs.count, totalTabCount, "The total tab count should not have changed")
    }

    func test_addTabsForURLs() {
        let subject = createSubject()

        subject.addTabsForURLs([URL(string: "https://www.mozilla.org/privacy/firefox")!], zombie: false, shouldSelectTab: false)

        XCTAssertEqual(subject.tabs.count, 1)
        XCTAssertEqual(subject.tabs.first?.url?.absoluteString, "https://www.mozilla.org/privacy/firefox")
        XCTAssertEqual(subject.tabs.first?.isPrivate, false)
    }

    func test_addTabsForURLs_forPrivateMode() {
        let subject = createSubject()

        subject.addTabsForURLs([URL(string: "https://www.mozilla.org/privacy/firefox")!], zombie: false, shouldSelectTab: false, isPrivate: true)

        XCTAssertEqual(subject.tabs.count, 1)
        XCTAssertEqual(subject.tabs.first?.url?.absoluteString, "https://www.mozilla.org/privacy/firefox")
        XCTAssertEqual(subject.tabs.first?.isPrivate, true)
    }

    // MARK: - Test findRightOrLeftTab helper

    func testFindRightOrLeftTab_forEmptyArray() {
        // Set up a tab array as follows:
        // [] Empty
        // Will pretend to delete a normal active tab at index 0.
        // Expect no tab to be returned.
        let tabManager = createSubject()

        let deletedIndex = 0 // Pretend the only tab in the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: []
        XCTAssertNil(rightOrLeftTab, "Cannot return a tab when the array is empty")
    }

    func testFindRightOrLeftTab_forSingleTabInArray_ofSameType() {
        // Set up a tab array as follows:
        // [A1]
        // Will pretend to delete a normal active tab at index 0.
        // Expect A1 tab to be returned.
        let numberActiveTabs = 1
        let tabManager = createSubject(tabs: generateTabs(ofType: .normalActive, count: numberActiveTabs))

        let deletedIndex = 0
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(rightOrLeftTab, tabManager.tabs[safe: 0], "Should return neighbour of same type, as one exists")
    }

    func testFindRightOrLeftTab_forSingleTabInArray_ofDifferentType() {
        // Set up a tab array as follows:
        // [A1]
        // Will pretend to delete a private tab at index 0.
        // Expect no tab to be returned (no other private tabs).
        let numberActiveTabs = 1
        let tabManager = createSubject(tabs: generateTabs(ofType: .normalActive, count: numberActiveTabs))

        let deletedIndex = 0
        let removedTab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID) // Private tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNil(rightOrLeftTab, "Cannot return neighbour tab of same type, as no other private tabs exist")
    }

    func testFindRightOrLeftTab_forDeletedIndexInMiddle_uniformTabTypes() {
        // Set up a tab array as follows:
        // [A1, A2, A3, A4, A5, A6, A7]
        //   0   1   2   3   4   5   6
        // Will pretend to delete a normal active tab at index 3.
        // Expect A4 tab to be returned.
        let numberActiveTabs = 7
        let tabManager = createSubject(tabs: generateTabs(ofType: .normalActive, count: numberActiveTabs))

        let deletedIndex = 3
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(rightOrLeftTab, tabManager.tabs[safe: 3], "Should pick tab A4 at the same position as deletedIndex")
    }

    func testFindRightOrLeftTab_forDeletedIndexInMiddle_mixedTabTypes() {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal active tab at index 5.
        // Expect to return A3 (nearest active tab on right).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 5 // Pretend a normal active tab between A2 and I2 was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [A1, A2, A3, A4]
        // For "deleted" index 5 in the main array, that should be mapped down to index 2 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right first, in this case, A3 (third active tab)
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalActiveTabs[safe: 2],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    func testFindRightOrLeftTab_forDeletedIndexAtStart() {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal active tab at index 0.
        // Expect to return A1 (nearest active tab on right).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()
        let deletedIndex = 0 // Pretend a normal active tab at the start of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [A1, A2, A3, A4]
        // For "deleted" index 0 in the main array, that should be mapped down to index 0 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right first, in this case, A1 (first active tab)
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalActiveTabs[safe: 0],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    func testFindRightOrLeftTab_forDeletedIndexAtEnd() {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal active tab at index 9.
        // Expect to return A4 (nearest active tab on left, since there is no right tab available).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 9 // Pretend a normal active tab at the end of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [A1, A2, A3, A4]
        // For "deleted" index 9 in the main array, that should be mapped down to index 4 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the left (since no right tab exists), in this case, A4
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalActiveTabs[safe: 3],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    func testFindRightOrLeftTab_prefersRightTabOverLeftTab() {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete an inactive active tab at index 4.
        // Expect to return I2 (nearest inactive tab on the right, as right is given preference to left).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 4 // Pretend a normal active tab at the end of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        removedTab.lastExecutedTime = Date().lastMonth.toTimestamp() // Inactive normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [I1, I2]
        // For "deleted" index 4 in the main array, that should be mapped down to index 1 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right, in this case, I2
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.inactiveTabs[safe: 1],
            "Should choose the second inactive tab as the nearest neighbour on the right"
        )
    }

    // MARK: - Remove Tab (removing selected normal active tab)

    @MainActor
    func testRemoveTab_removeSelectedNormalActiveTab_selectsRecentParentNormalActiveTab() async throws {
        let numberNormalActiveTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normalActive, count: numberNormalActiveTabs))
        guard let firstNormalActiveTab = tabManager.normalActiveTabs[safe: 0],
              let secondNormalActiveTab = tabManager.normalActiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondNormalActiveTab.parent = firstNormalActiveTab

        // Make all the tabs slightly stale
        tabManager.normalActiveTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the parent tab the most recent tab
        firstNormalActiveTab.lastExecutedTime = Date().toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        await tabManager.removeTab(secondNormalActiveTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, we expect its recent parent to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstNormalActiveTab, "Should have selected the parent tab, it's most recent")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The first tab, the parent, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectedNormalActiveTab_selectsRightOrLeftNormalActiveTab_ifNoParent() async throws {
        let numberNormalActiveTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normalActive, count: numberNormalActiveTabs))
        guard let secondNormalActiveTab = tabManager.normalActiveTabs[safe: 1],
              let thirdNormalActiveTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        await tabManager.removeTab(secondNormalActiveTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalActiveTab, "Should select tab on the right since no parent")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectedNormalActiveTab_selectsRightOrLeftActiveTab_ifParentNotRecent() async throws {
        let numberNormalActiveTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normalActive, count: numberNormalActiveTabs))
        guard let firstNormalActiveTab = tabManager.normalActiveTabs[safe: 0],
              let secondNormalActiveTab = tabManager.normalActiveTabs[safe: 1],
              let thirdNormalActiveTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondNormalActiveTab.parent = firstNormalActiveTab

        // Make the parent tab staler than the others (not recent)
        firstNormalActiveTab.lastExecutedTime = Date().dayBefore.toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        await tabManager.removeTab(secondNormalActiveTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalActiveTab, "Should select tab on the right since parent is stale")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    // MARK: - Remove Tab (removing selected private tab)

    @MainActor
    func testRemoveTab_removeSelectedPrivateTab_selectsRecentParentPrivateTab() async throws {
        let numberPrivateTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .privateAny, count: numberPrivateTabs))
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second private tab
        secondPrivateTab.parent = firstPrivateTab

        // Make all the tabs slightly stale
        tabManager.normalActiveTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the parent tab the most recent tab
        firstPrivateTab.lastExecutedTime = Date().toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        await tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, we expect its recent parent to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "Should have selected the parent tab, as it is most recent")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The first tab, the parent, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectedPrivateTab_selectsRightOrLeftPrivateTab_ifNoRecentParent() async throws {
        let numberPrivateTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .privateAny, count: numberPrivateTabs))
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1],
              let thirdPrivateTab = tabManager.privateTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second private tab
        secondPrivateTab.parent = firstPrivateTab

        // But make the parent tab a bit stale, so it's not the most recent tab (so it should not be selected)
        firstPrivateTab.lastExecutedTime = Date().dayBefore.toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        await tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed with no parent, we expect the right tab to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, thirdPrivateTab, "Should have selected the tab on the right")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now at index 1, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectedPrivateTab_selectsRightOrLeftPrivateTab_ifParentNotRecent() async throws {
        let numberPrivateTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .privateAny, count: numberPrivateTabs))
        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1],
              let thirdPrivateTab = tabManager.privateTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondPrivateTab.parent = firstPrivateTab

        // Make the parent tab staler than the others (not recent)
        firstPrivateTab.lastExecutedTime = Date().dayBefore.toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        // Remove the selected tab
        await tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, thirdPrivateTab, "Should select tab on the right since parent is stale")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    // MARK: - Remove Tab (removing selected inactive tab, weird edge case)

    @MainActor
    func testRemoveTab_removeSelectedNormalInactiveTab_createsNewNormalActiveTab() async throws {
        // This is a weird edge case that shouldn't happen in practice, but let's make sure we can handle it.
        // If the selected tab is removed, and it also happens to be inactive, treat it like a normal active tab.

        let numberInactiveTabs = 3
        let numberActiveTabs = 3
        let inactiveTabs = generateTabs(ofType: .normalInactive, count: numberInactiveTabs)
        let activeTabs = generateTabs(ofType: .normalActive, count: numberActiveTabs)
        let tabManager = createSubject(tabs: inactiveTabs + activeTabs)

        guard let secondInactiveTab = tabManager.inactiveTabs[safe: 1],
              let secondNormalTab = tabManager.normalActiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        let initialTabs = tabManager.tabs

        // Make all the active tabs slightly stale (but not inactive)
        tabManager.normalActiveTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the second normal active tab the most recent
        secondNormalTab.lastExecutedTime = Date().toTimestamp()

        // Set the first inactive tab as selected
        await MainActor.run {
            tabManager.selectTab(secondInactiveTab)
            // Selecting a tab makes it active, so reset to inactive again with an old timestamp
            secondInactiveTab.lastExecutedTime = Date().lastMonth.toTimestamp()
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs + numberActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondInactiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected inactive tab
        await tabManager.removeTab(secondInactiveTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When a selected inactive tab is removed, this is a strange state. Handle like regular active tabs being cleared.
        // In this case, we'd expect the most recent active tab to be chosen since `firstInactiveTab` has no parent and no
        // left/right tab that's viable in the array (surrounded by two inactive tabs).
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs + numberActiveTabs, "Size won't change as new tab replaces")
        XCTAssertEqual(tabManager.inactiveTabs.count, numberInactiveTabs - 1)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberActiveTabs + 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        for tab in initialTabs {
            XCTAssertNotEqual(tabManager.selectedTab, tab, "None of the initial tabs should be selected")
        }
        XCTAssertEqual(tabManager.selectedIndex, 5, "The newly appended active tab should be selected")
    }

    // MARK: - Remove Tab (removing last private tab)

    @MainActor
    func testRemoveTab_removeLastPrivateTab_hasNormalTabs_selectsRecentNormalTab() async throws {
        let numberPrivateTabs = 1
        let numberNormalActiveTabs = 3
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let normalActiveTabs = generateTabs(ofType: .normalActive, count: numberNormalActiveTabs)

        let tabManager = createSubject(tabs: privateTabs + normalActiveTabs)
        guard let privateTab = tabManager.privateTabs[safe: 0],
              let secondNormalTab = tabManager.normalActiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make all the active tabs slightly stale (but not inactive)
        tabManager.normalActiveTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the third normal active tab the most recent
        secondNormalTab.lastExecutedTime = Date().toTimestamp()

        // Set the private tab as selected
        await MainActor.run {
            tabManager.selectTab(privateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs + numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, privateTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the selected single private tab
        await tabManager.removeTab(privateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there's a recent active tab, we expect that to be selected
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalTab, "Should select the most recently executed normal active tab")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The second normal tab should be selected")
    }

    @MainActor
    func testRemoveTab_removeLastPrivateTab_hasInactiveTabs_hasNoActiveTabs_createsNewNormalActiveTab() async throws {
        let numberNormalInactiveTabs = 3
        let numberPrivateTabs = 1
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let normalInactiveTabs = generateTabs(ofType: .normalInactive, count: numberNormalInactiveTabs)

        let tabManager = createSubject(tabs: normalInactiveTabs + privateTabs)
        guard let privateTab = tabManager.privateTabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        await MainActor.run {
            tabManager.selectTab(privateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs + numberPrivateTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, privateTab)
        XCTAssertEqual(tabManager.selectedIndex, 3)

        // Remove the only active tab, which is selected
        await tabManager.removeTab(privateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last normal active tab is removed, even if there are normal active tabs, we expect a new normal active
        // tab to be added as we don't want to surface an old inactive tab.
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs + 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, privateTab, "The added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 3, "A new tab should be appended and selected")
    }

    @MainActor
    func testRemoveTab_removeLastPrivateTab_isOnlyTab_createsNewNormalActiveTab() async throws {
        let numberPrivateTabs = 1
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let tabManager = createSubject(tabs: privateTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the private tab as selected
        await MainActor.run {
            tabManager.selectTab(firstTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last selected private tab
        await tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there are no normal active tabs,
        // we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    @MainActor
    func testRemoveTab_removeLastPrivateTab_onlyOtherTabsAreNormalInactiveTabs_createsNewNormalActiveTab() async throws {
        let numberPrivateTabs = 1
        let numberInactiveTabs = 3
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let normalInactiveTabs = generateTabs(ofType: .normalInactive, count: numberInactiveTabs)

        let tabManager = createSubject(tabs: privateTabs + normalInactiveTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        let initialTabs = tabManager.tabs

        // Set the private tab as selected
        await MainActor.run {
            tabManager.selectTab(firstTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs + numberInactiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last selected private tab
        await tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there are no only inactive normal tabs remaining,
        // we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs + numberInactiveTabs, "Removed tab is replaced, count same")
        XCTAssertEqual(tabManager.inactiveTabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1, "A new active tab should be added")
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        for tab in initialTabs {
            XCTAssertNotEqual(tabManager.selectedTab, tab, "None of the initial tabs should be selected")
        }
        XCTAssertEqual(tabManager.selectedIndex, 3, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing last normal active tab)

    @MainActor
    func testRemoveTab_removeLastNormalActiveTab_isOnlyTab_createsNewNormalActiveTab() async throws {
        let numberNormalActiveTabs = 1
        let normalActiveTabs = generateTabs(ofType: .normalActive, count: numberNormalActiveTabs)

        let tabManager = createSubject(tabs: normalActiveTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        await MainActor.run {
            tabManager.selectTab(firstTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last tab, which is active and selected
        await tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last active tab is removed, we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    @MainActor
    func testRemoveTab_removeLastNormalActiveTab_hasInactiveTabs_createsNewNormalActiveTab() async throws {
        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 1
        let normalActiveTabs = generateTabs(ofType: .normalActive, count: numberNormalActiveTabs)
        let normalInactiveTabs = generateTabs(ofType: .normalInactive, count: numberNormalInactiveTabs)

        let tabManager = createSubject(tabs: normalInactiveTabs + normalActiveTabs)
        guard let activeTab = tabManager.normalActiveTabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        await MainActor.run {
            tabManager.selectTab(activeTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs + numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, activeTab)
        XCTAssertEqual(tabManager.selectedIndex, 3)

        // Remove the only active tab, which is selected
        await tabManager.removeTab(activeTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last normal active tab is removed, even if there are normal active tabs, we expect a new normal active
        // tab to be added as we don't want to surface an old inactive tab.
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs + 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, activeTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 3, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing last normal inactive tab, which means it's selected, another weird edge case)

    @MainActor
    func testRemoveTab_removeLastNormalInactiveTab_isOnlyTab_createsNewNormalActiveTab() async throws {
        let numberInactiveTabs = 1
        let inactiveTabs = generateTabs(ofType: .normalInactive, count: numberInactiveTabs)
        let tabManager = createSubject(tabs: inactiveTabs)

        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        await MainActor.run {
            tabManager.selectTab(firstTab)
            // Selecting a tab makes it active, so reset to inactive again with an old timestamp
            firstTab.lastExecutedTime = Date().lastMonth.toTimestamp()
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last tab, which is inactive and selected
        await tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected inactive tab is removed, we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing one unselected tabs among many)

    @MainActor
    func testRemoveTab_removeUnselectedNormalActiveTab_fromManyMixedTabs_causesArrayShift() async throws {
        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberNormalActiveTabs
        // Mix up the normal active and inactive tabs in the `tabs` array
        let normalInactive = generateTabs(ofType: .normalInactive, count: 1)
        let normalActive = generateTabs(ofType: .normalActive, count: 2)
        let normalInactive2 = generateTabs(ofType: .normalInactive, count: 2)
        let normalActive2 = generateTabs(ofType: .normalActive, count: 1)

        let tabManager = createSubject(tabs: normalInactive + normalActive + normalInactive2 + normalActive2)

        guard let firstNormalActiveTab = tabManager.normalActiveTabs[safe: 0],
              let thirdNormalActiveTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 3rd normal active tab as selected
        await MainActor.run {
            tabManager.selectTab(thirdNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 5)

        // Remove the unselected normal active tab at an index smaller than the selected tab to cause an array shift for the
        // selected tab
        await tabManager.removeTab(firstNormalActiveTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalActiveTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 4, "The selected tab index should have shifted left")
    }

    @MainActor
    func testRemoveTab_removeUnselectedNormalActiveTab_fromManyMixedTabs_noArrayShift() async throws {
        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberNormalActiveTabs
        // Mix up the normal active and inactive tabs in the `tabs` array
        let normalInactive1 = generateTabs(ofType: .normalInactive, count: 1)
        let normalActive1 = generateTabs(ofType: .normalActive, count: 2)
        let normalInactive2 = generateTabs(ofType: .normalInactive, count: 2)
        let normalActive2 = generateTabs(ofType: .normalActive, count: 1)

        let tabManager = createSubject(tabs: normalInactive1 + normalActive1 + normalInactive2 + normalActive2)

        guard let firstNormalActiveTab = tabManager.normalActiveTabs[safe: 0],
              let thirdNormalActiveTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 1st normal active tab as selected
        await MainActor.run {
            tabManager.selectTab(firstNormalActiveTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstNormalActiveTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the unselected normal active tab at an index larger than the selected tab so no array shift is necessary
        // for the selected tab
        await tabManager.removeTab(thirdNormalActiveTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstNormalActiveTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The selected tab index should not have shifted")
    }

    @MainActor
    func testRemoveTab_removeUnselectedPrivateTab_fromManyMixedTabs_causesArrayShift() async throws {
        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberPrivateTabs + numberNormalActiveTabs
        let normalInactive = generateTabs(ofType: .normalInactive, count: numberNormalInactiveTabs)
        let normalActive = generateTabs(ofType: .normalActive, count: numberNormalActiveTabs)
        let privateAny = generateTabs(ofType: .privateAny, count: numberPrivateTabs)

        let tabManager = createSubject(tabs: normalInactive + normalActive + privateAny)

        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 2nd private tab as selected (will cause a shift when the 1st private tab is deleted)
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 7)

        // Remove the unselected private tab at an index smaller than the selected tab to cause an array shift for the
        // selected tab
        await tabManager.removeTab(firstPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 6, "The selected tab index should have shifted left")
    }

    @MainActor
    func testRemoveTab_removeUnselectedPrivateTab_fromManyMixedTabs_noArrayShift() async throws {
        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberPrivateTabs + numberNormalActiveTabs
        let normalInactive = generateTabs(ofType: .normalInactive, count: numberNormalInactiveTabs)
        let normalActive = generateTabs(ofType: .normalActive, count: numberNormalActiveTabs)
        let privateAny = generateTabs(ofType: .privateAny, count: numberPrivateTabs)

        let tabManager = createSubject(tabs: normalInactive + normalActive + privateAny)

        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let thirdPrivateTab = tabManager.privateTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first private tab as selected
        await MainActor.run {
            tabManager.selectTab(firstPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 6)

        // Remove the unselected private tab at an index larger than the selected private tab so no array shift is necessary
        // for the selected tab
        await tabManager.removeTab(thirdPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 6, "The selected tab index should have shifted left")
    }

    @MainActor
    func testRemoveTab_removeUnselectedNormalInactiveTab_fromManyMixedTabs_causesArrayShift() async throws {
        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numberNormalInactiveTabs + numberPrivateTabs + numberNormalActiveTabs
        let normalInactive = generateTabs(ofType: .normalInactive, count: numberNormalInactiveTabs)
        let normalActive = generateTabs(ofType: .normalActive, count: numberNormalActiveTabs)
        let privateAny = generateTabs(ofType: .privateAny, count: numberPrivateTabs)

        let tabManager = createSubject(tabs: normalInactive + normalActive + privateAny)

        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let firstNormalInactiveTab = tabManager.inactiveTabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 1st private tab as selected (if you set a normal tab, the private tabs get automatically closed on select)
        await MainActor.run {
            tabManager.selectTab(firstPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 6)

        // Remove the unselected inactive normal tab at an index smaller than the selected tab to cause an array shift for
        // the selected tab
        await tabManager.removeTab(firstNormalInactiveTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs - 1)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 5, "The selected tab index should have shifted left")
    }

    // MARK: - Remove Tab (removing unselected tabs at array bounds)

    @MainActor
    func testRemoveTab_removeFirstTab_removeLastTime_removeOnlyTab() async throws {
        let numberNormalActiveTabs = 3
        let tabs = generateTabs(ofType: .normalActive, count: numberNormalActiveTabs)

        let tabManager = createSubject(tabs: tabs)

        guard let firstTab = tabManager.normalActiveTabs[safe: 0],
              let secondTab = tabManager.normalActiveTabs[safe: 1],
              let thirdTab = tabManager.normalActiveTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // [1] First, remove the tab at index 0
        await tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should have shifted left")

        // [2] Second, remove the tab at count - 1 (last tab)
        await tabManager.removeTab(thirdTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs - 2)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs - 2)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should not change")

        // [3] Finally, remove the only tab (which is also the selected tab)
        await tabManager.removeTab(secondTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // We expect a new normal active tab will be created
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, secondTab, "This tab should have been removed")
        XCTAssertEqual(tabManager.selectedIndex, 0, "Index of new normal active tab")
    }

    // MARK: - removeAllInactiveTabs (removing unselected tabs at array bounds)

    @MainActor
    func testRemoveAllInactiveTabs_whenOnlyInactiveTabs_opensNewActiveTab() async throws {
        // This is a strange edge case that can happen if your active tab goes inactive (most commonly with 10s debug timer).
        let numberNormalInactiveTabs = 3
        let tabs = generateTabs(ofType: .normalInactive, count: numberNormalInactiveTabs)
        let tabManager = createSubject(tabs: tabs)

        guard let secondTab = tabManager.inactiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected (edge case that an inactive tab is the selected tab)
        await MainActor.run {
            tabManager.selectTab(secondTab)
            // Selecting a tab makes it active, so reset to inactive again with an old timestamp
            secondTab.lastExecutedTime = Date().lastMonth.toTimestamp()
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        await tabManager.removeAllInactiveTabs()
        try await Task.sleep(nanoseconds: sleepTime)

        // We expect a new normal active tab will be created, all inactive tabs removed
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, secondTab, "This tab should have been removed")
        XCTAssertEqual(tabManager.selectedIndex, 0, "Index of new normal active tab")
    }

    @MainActor
    func testRemoveAllInactiveTabs_whenNormalActiveTabsExist_isNormalBrowsingMode() async throws {
        let numberNormalInactiveTabs = 3
        let numberNormalActiveTabs = 3
        let normalInactive = generateTabs(ofType: .normalInactive, count: numberNormalInactiveTabs)
        let normalActive = generateTabs(ofType: .normalActive, count: numberNormalActiveTabs)
        let tabManager = createSubject(tabs: normalInactive + normalActive)

        guard let secondTab = tabManager.normalActiveTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second normal tab as selected
        await MainActor.run {
            tabManager.selectTab(secondTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs + numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab)
        XCTAssertEqual(tabManager.selectedIndex, 4)

        await tabManager.removeAllInactiveTabs()
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, numberNormalActiveTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not have changed")
        XCTAssertEqual(tabManager.selectedIndex, 1, "Index will have shifted by the number of removed inactive tabs")
    }

    @MainActor
    func testRemoveAllInactiveTabs_whenOnlyPrivateTabsExist_isPrivateBrowsingMode() async throws {
        let numberNormalInactiveTabs = 3
        let numberNormalPrivateTabs = 3
        let normalInactive = generateTabs(ofType: .normalInactive, count: numberNormalInactiveTabs)
        let privateAny = generateTabs(ofType: .privateAny, count: numberNormalPrivateTabs)
        let tabManager = createSubject(tabs: normalInactive + privateAny)

        guard let secondPrivateTab = tabManager.privateTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second private tab as selected
        await MainActor.run {
            tabManager.selectTab(secondPrivateTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalInactiveTabs + numberNormalPrivateTabs)
        XCTAssertEqual(tabManager.inactiveTabs.count, numberNormalInactiveTabs)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberNormalPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 4)

        await tabManager.removeAllInactiveTabs()
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, numberNormalPrivateTabs, "Number of private tabs should not have changed")
        XCTAssertEqual(tabManager.inactiveTabs.count, 0)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberNormalPrivateTabs, "Private tab count should not change")
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab, "The selected tab should not have changed")
        XCTAssertEqual(tabManager.selectedIndex, 1, "Index will have shifted by the number of removed inactive tabs")
    }

    // MARK: - Helper methods

    private func createSubject(tabs: [Tab] = [], windowUUID: WindowUUID? = nil) -> TabManagerImplementation {
        let subject = TabManagerImplementation(
            profile: mockProfile,
            imageStore: mockDiskImageStore,
            uuid: ReservedWindowUUID(uuid: windowUUID ?? tabWindowUUID, isNew: false),
            tabDataStore: mockTabStore,
            tabSessionStore: mockSessionStore,
            tabs: tabs
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setIsDeeplinkOptimizationRefactorEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.deeplinkOptimizationRefactorFeature.with { _, _ in
            return DeeplinkOptimizationRefactorFeature(enabled: enabled)
        }
    }

    private func setIsPDFRefactorEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.pdfRefactorFeature.with { _, _ in
            return PdfRefactorFeature(enabled: enabled)
        }
    }

    enum TabType {
        case normalActive
        case normalInactive
        case privateAny // `private` alone is a reserved compiler keyword
    }

    private func generateTabs(ofType type: TabType = .normalActive, count: Int) -> [Tab] {
        var tabs = [Tab]()
        for i in 0..<count {
            let tab: Tab

            switch type {
            case .normalActive:
                tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
            case .normalInactive:
                let lastMonthDate = Date().lastMonth
                tab = Tab(profile: MockProfile(), windowUUID: tabWindowUUID, tabCreatedTime: lastMonthDate)
            case .privateAny:
                tab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID)
            }

            tab.url = testURL(count: i)
            tabs.append(tab)
        }

        return tabs
    }

    private func getMockTabData(count: Int) -> [TabData] {
        var tabData = [TabData]()
        for i in 0..<count {
            let tab = TabData(id: UUID(),
                              title: "Firefox",
                              siteUrl: testURL(count: i).absoluteString,
                              faviconURL: "",
                              isPrivate: false,
                              lastUsedTime: Date(),
                              createdAtTime: Date(),
                              tabGroupData: TabGroupData())
            tabData.append(tab)
        }
        return tabData
    }

    /// Generate a test URL given a count that is used as query parameter to get diversified URLs
    private func testURL(count: Int) -> URL {
        return URL(string: "https://mozilla.com?item=\(count)")!
    }

    private func setupForFindRightOrLeftTab_mixedTypes() -> TabManagerImplementation {
        // Set up a tab array as follows:
        // [A1, P1, P2, I1, A2, I2, A3, A4, P3]
        //   0   1   2   3   4   5   6   7   8
        let tabs1 = generateTabs(ofType: .normalActive, count: 1)
        let tabs2 = generateTabs(ofType: .privateAny, count: 2)
        let tabs3 = generateTabs(ofType: .normalInactive, count: 1)
        let tabs4 = generateTabs(ofType: .normalActive, count: 1)
        let tabs5 = generateTabs(ofType: .normalInactive, count: 1)
        let tabs6 = generateTabs(ofType: .normalActive, count: 2)
        let tabs7 = generateTabs(ofType: .privateAny, count: 1)

        let tabManager = createSubject(tabs: tabs1 + tabs2 + tabs3 + tabs4 + tabs5 + tabs6 + tabs7)
        // Check preconditions
        XCTAssertEqual(tabManager.tabs.count, 9)
        XCTAssertEqual(tabManager.normalActiveTabs.count, 4)
        XCTAssertEqual(tabManager.inactiveTabs.count, 2)
        XCTAssertEqual(tabManager.privateTabs.count, 3)
        return tabManager
    }
}

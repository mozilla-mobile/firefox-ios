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
    /// 9 Sep 2001 8:00 pm GMT + 0
    let testDate = Date(timeIntervalSince1970: 1_000_065_600)

    override func setUp() {
        super.setUp()

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
    }

    override func tearDown() {
        mockProfile = nil
        mockDiskImageStore = nil
        mockTabStore = nil
        mockSessionStore = nil
        super.tearDown()
    }

    @MainActor
    func testRecentlyAccessedNormalTabs() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .normalOlderLastMonth, count: 2))
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 2))
        let subject = createSubject(tabs: tabs)
        var normalTabs = subject.recentlyAccessedNormalTabs
        XCTAssertEqual(normalTabs.count, 7)
        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
        normalTabs = subject.recentlyAccessedNormalTabs
        XCTAssertEqual(normalTabs.count, 7)
        UserDefaults.standard.removeObject(forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
    }

    @MainActor
    func testTabIndexSubscript() {
        let subject = createSubject(tabs: generateTabs(count: 5))
        let tab = subject[0]
        XCTAssertNotNil(tab)
    }

    @MainActor
    func testRemoveTabs() {
        let subject = createSubject(tabs: generateTabs(count: 5))
        let tabs = subject.tabs
        subject.removeTabs(tabs)
        XCTAssertEqual(subject.tabs.count, 0)
    }

    @MainActor
    func testRemoveTabsByURLs() {
        let subject = createSubject(tabs: generateTabs(count: 5))
        subject.removeTabs(by: [URL(string: "https://mozilla.com?item=4")!, URL(string: "https://mozilla.com?item=1")!])
        let remainingURLs = subject.tabs.compactMap { $0.url?.absoluteString }
        XCTAssertEqual(remainingURLs, ["https://mozilla.com?item=0", "https://mozilla.com?item=2", "https://mozilla.com?item=3"])
    }

    @MainActor
    func testRemoveAllTabsForPrivateMode() {
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 4))
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.tabs.count, 9)
        subject.removeAllTabs(isPrivateMode: true)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    // This test has to be run on the main thread since we are messing with the WebView.
    @MainActor
    func testRemoveAllTabsCallsSaveTabSession() {
        let subject = createSubject()
        let tab = subject.addTab(URLRequest(url: URL(string: "https://mozilla.com")!), afterTab: nil, isPrivate: false)
        subject.selectTab(tab)
        subject.removeAllTabs(isPrivateMode: false)

        // Save tab session is actually called 3 times for one remove all call
        // 1. Save tab session for currently selected tab before delete to preserve scroll position
        // 1. AddTab for the new created homepage tab calls commitChanges
        // 2. selectTab persists changes for currently selected tab before moving to new Tab
        XCTAssertEqual(mockSessionStore.saveTabSessionCallCount, 3)
    }

    @MainActor
    func testRemoveAllTabsForNotPrivateModeWhenClosePrivateTabsSettingIsFalse() {
        (mockProfile.prefs as? MockProfilePrefs)?.things[PrefsKeys.Settings.closePrivateTabs] = false
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 4))
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.tabs.count, 9)
        subject.removeAllTabs(isPrivateMode: false)
        // 5, private mode tabs (4) plus one new normal tab (1)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    @MainActor
    func testRemoveAllTabsForNotPrivateModeWhenClosePrivateTabsSettingIsTrue() {
        (mockProfile.prefs as? MockProfilePrefs)?.things[PrefsKeys.Settings.closePrivateTabs] = true
        var tabs = generateTabs(count: 5)
        tabs.append(contentsOf: generateTabs(ofType: .privateAny, count: 4))
        let subject = createSubject(tabs: tabs)
        XCTAssertEqual(subject.tabs.count, 9)
        subject.removeAllTabs(isPrivateMode: false)
        // One new normal tab (1)
        XCTAssertEqual(subject.tabs.count, 1)
    }

    @MainActor
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

    @MainActor
    func testUndoCloseTab() {
        let subject = createSubject()
        let tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
        tab.url = URL(string: "https://mozilla.com/")!
        XCTAssertEqual(subject.selectedIndex, -1)
        subject.backupCloseTab = BackupCloseTab(tab: tab, isSelected: true)
        subject.undoCloseTab()
        XCTAssertEqual(subject.selectedIndex, 0)
    }

    @MainActor
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
    @MainActor
    func testSelectTab_pauseCurrentDocumentDownload() throws {
        let tabs = generateTabs(count: 2)
        let document = MockTemporaryDocument(withFileURL: URL(string: "https://www.example.com")!)
        let subject = createSubject(tabs: tabs)

        let tab = try XCTUnwrap(tabs.first)
        tab.enqueueDocument(document)

        subject.selectTab(tabs[1], previous: tab)

        XCTAssertEqual(document.pauseDownloadCalled, 1)
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

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [tabs = subject.tabs] in
            XCTAssertEqual(tabs.count, 4)
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

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [tabs = subject.tabs] in
            XCTAssertEqual(tabs.count, 3)
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

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [tabs = subject.tabs, selectedTab = subject.selectedTab] in
            // Tabs count has to be same as restoration data, since deeplink tab has same of URL of a restored tab.
            XCTAssertEqual(tabs.count, tabData.count)
            XCTAssertEqual(selectedTab, deeplinkTab)
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

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [tabs = subject.tabs, tabUUID = subject.selectedTab?.tabUUID] in
            XCTAssertEqual(tabs.count, tabData.count)
            XCTAssertEqual(tabUUID, previouslySelectedTabData.id.uuidString)
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

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [tabs = subject.tabs, selectedTab = subject.selectedTab] in
            XCTAssertEqual(tabs.count, tabData.count + 1)
            XCTAssertEqual(selectedTab, deeplinkTab)
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

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [tabs = subject.tabs] in
            // Tabs count has to be the sum of deeplink and restored tabs, since the deeplink tab is not present in
            // the restored once.
            XCTAssertEqual(tabs.count, 5)
            expectation.fulfill()
        }

        subject.restoreTabs()
        wait(for: [expectation])
    }

    @MainActor
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
            ensureMainThread {
                let filteredTabs = subject.tabs.filter {
                    $0.tabUUID == deeplinkTab.tabUUID
                }
                // There has to be only one tab present
                XCTAssertEqual(filteredTabs.count, 1)
                expectation.fulfill()
            }
        }

        subject.restoreTabs()
        wait(for: [expectation])
    }

    // MARK: - Save tabs
    @MainActor
    func testPreserveTabsWithNoTabs() async throws {
        let subject = createSubject()
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 0)
        XCTAssertEqual(subject.tabs.count, 0)
    }

    @MainActor
    func testPreserveTabsWithOneTab() async throws {
        let subject = createSubject(tabs: generateTabs(count: 1))
        subject.tabRestoreHasFinished = true
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(subject.tabs.count, 1)
    }

    @MainActor
    func testPreserveTabsWithManyTabs() async throws {
        let subject = createSubject(tabs: generateTabs(count: 5))
        subject.tabRestoreHasFinished = true
        subject.preserveTabs()
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    // MARK: - Save preview screenshot
    @MainActor
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

    @MainActor
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

    @MainActor
    func testGetTabsAndChangeLastExecutedTime() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        let totalTabCount = 3
        let subject = createSubject(tabs: generateTabs(count: totalTabCount))

        // Preconditions
        XCTAssertEqual(subject.tabs.count, totalTabCount, "Expected 3 newly added tabs.")
        XCTAssertEqual(subject.normalTabs.count, totalTabCount, "All tabs should be active on initialization")

        // Override lastExecutedTime of 1st tab to be recent (i.e. active)
        // and lastExecutedTime of other 2 to be distant past (i.e. inactive)
        let lastExecutedDate = Calendar.current.add(numberOfDays: 1, to: Date())!
        subject.tabs[0].lastExecutedTime = lastExecutedDate.toTimestamp()
        subject.tabs[1].lastExecutedTime = 0
        subject.tabs[2].lastExecutedTime = 0

        // Test
        XCTAssertEqual(subject.normalTabs.count, totalTabCount, "The total tab count should not have changed")
    }

    @MainActor
    func test_addTabsForURLs() {
        let subject = createSubject()

        subject.addTabsForURLs([URL(string: "https://www.mozilla.org/privacy/firefox")!], zombie: false, shouldSelectTab: false)

        XCTAssertEqual(subject.tabs.count, 1)
        XCTAssertEqual(subject.tabs.first?.url?.absoluteString, "https://www.mozilla.org/privacy/firefox")
        XCTAssertEqual(subject.tabs.first?.isPrivate, false)
    }

    @MainActor
    func test_addTabsForURLs_forPrivateMode() {
        let subject = createSubject()

        subject.addTabsForURLs([URL(string: "https://www.mozilla.org/privacy/firefox")!], zombie: false, shouldSelectTab: false, isPrivate: true)

        XCTAssertEqual(subject.tabs.count, 1)
        XCTAssertEqual(subject.tabs.first?.url?.absoluteString, "https://www.mozilla.org/privacy/firefox")
        XCTAssertEqual(subject.tabs.first?.isPrivate, true)
    }

    // MARK: - Test findRightOrLeftTab helper
    @MainActor
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

    @MainActor
    func testFindRightOrLeftTab_forSingleTabInArray_ofSameType() {
        // Set up a tab array as follows:
        // [A1]
        // Will pretend to delete a normal active tab at index 0.
        // Expect A1 tab to be returned.
        let numberActiveTabs = 1
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: numberActiveTabs))

        let deletedIndex = 0
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(rightOrLeftTab, tabManager.tabs[safe: 0], "Should return neighbour of same type, as one exists")
    }

    @MainActor
    func testFindRightOrLeftTab_forSingleTabInArray_ofDifferentType() {
        // Set up a tab array as follows:
        // [A1]
        // Will pretend to delete a private tab at index 0.
        // Expect no tab to be returned (no other private tabs).
        let numberActiveTabs = 1
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: numberActiveTabs))

        let deletedIndex = 0
        let removedTab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID) // Private tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNil(rightOrLeftTab, "Cannot return neighbour tab of same type, as no other private tabs exist")
    }

    @MainActor
    func testFindRightOrLeftTab_forDeletedIndexInMiddle_uniformTabTypes() {
        // Set up a tab array as follows:
        // [A1, A2, A3, A4, A5, A6, A7]
        //   0   1   2   3   4   5   6
        // Will pretend to delete a normal active tab at index 3.
        // Expect A4 tab to be returned.
        let numberActiveTabs = 7
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: numberActiveTabs))

        let deletedIndex = 3
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Active normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(rightOrLeftTab, tabManager.tabs[safe: 3], "Should pick tab A4 at the same position as deletedIndex")
    }

    @MainActor
    func testFindRightOrLeftTab_forDeletedIndexInMiddle_mixedTabTypes() {
        // Set up a tab array as follows:
        // [N1, P1, P2, N2, N3, N4, N5, N6, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal tab at index 5.
        // Expect to return N3 (nearest normal tab on left).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 5 // Pretend a normal tab between N3 and N5 was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [N1, N2, N3, N4, N5, N6]
        // For "deleted" index 5 in the main array, that should be mapped down to index 2 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right first, in this case, N5 (fourth normal tab)
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalTabs[safe: 3],
            "Should choose the third normal tab as the nearest neighbour on the right"
        )
    }

    @MainActor
    func testFindRightOrLeftTab_forDeletedIndexAtStart() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        // Set up a tab array as follows:
        // [N1, P1, P2, N2, N3, N4, N5, N6, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal active tab at index 0.
        // Expect to return N2 (nearest active tab on right).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()
        let deletedIndex = 0 // Pretend a normal tab at the start of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [N1, N2, N3, N4, N5, N6]
        // For "deleted" index 0 in the main array, that should be mapped down to index 0 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right first, in this case, N2 (first active tab)
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalTabs[safe: 0],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    @MainActor
    func testFindRightOrLeftTab_forDeletedIndexAtEnd() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        // Set up a tab array as follows:
        // [N1, P1, P2, N2, N3, N4, N5, N6, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a normal tab at index 9.
        // Expect to return N6 (nearest active tab on left, since there is no right tab available).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 9 // Pretend a normal active tab at the end of the array was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID) // Normal tab

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [N1, N2, N3, N4, N5, N6]
        // For "deleted" index 9 in the main array, that should be mapped down to index 6 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the left (since no right tab exists), in this case, N6
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.normalTabs[safe: 5],
            "Should choose the second normal tab as the nearest neighbour on the right"
        )
    }

    @MainActor
    func testFindRightOrLeftTab_prefersRightTabOverLeftTab() {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        // Set up a tab array as follows:
        // [N1, P1, P2, N2, N3, N4, N5, N6, P3]
        //   0   1   2   3   4   5   6   7   8
        // Will pretend to delete a private tab at index 1.
        // Expect to return P2 (nearest private tab on the right, as right is given preference to left).
        let tabManager = setupForFindRightOrLeftTab_mixedTypes()

        let deletedIndex = 1 // Pretend a private tab was just deleted
        let removedTab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)

        let rightOrLeftTab = tabManager.findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex)

        // Subarray: [P1, P2, P3]
        // For "deleted" index 1 in the main array, that should be mapped down to index 0 in the subarray.
        // Thus, `findRightOrLeftTab` should return the tab on the right, in this case, P2
        XCTAssertNotNil(rightOrLeftTab)
        XCTAssertEqual(
            rightOrLeftTab,
            tabManager.privateTabs[safe: 1],
            "Should choose the second inactive tab as the nearest neighbour on the right"
        )
    }

    // MARK: - Remove Tab (removing selected normal active tab)

    @MainActor
    func testRemoveTab_removeSelectednormalTab_selectsRecentParentnormalTab() async throws {
        let normalTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: normalTabs))
        guard let firstnormalTab = tabManager.normalTabs[safe: 0],
              let secondnormalTab = tabManager.normalTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondnormalTab.parent = firstnormalTab

        // Make all the tabs slightly stale
        tabManager.normalTabs.forEach { tab in
            tab.lastExecutedTime = Date().dayBefore.toTimestamp()
        }

        // Make the parent tab the most recent tab
        firstnormalTab.lastExecutedTime = Date().toTimestamp()

        // Set the second tab as selected
        tabManager.selectTab(secondnormalTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, normalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondnormalTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondnormalTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, we expect its recent parent to be selected.
        XCTAssertEqual(tabManager.tabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstnormalTab, "Should have selected the parent tab, it's most recent")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The first tab, the parent, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectedNormalTab_selectsRightOrLeftNormalTab_ifNoParent() async throws {
        let normalTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: normalTabs))
        guard let secondNormalTab = tabManager.normalTabs[safe: 1],
              let thirdNormalTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected
        tabManager.selectTab(secondNormalTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, normalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondNormalTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondNormalTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdNormalTab, "Should select tab on the right since no parent")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    @MainActor
    func testRemoveTab_removeSelectednormalTab_selectsRightOrLeftActiveTab_ifParentNotRecent() async throws {
        let normalTabs = 3
        let tabManager = createSubject(tabs: generateTabs(ofType: .normal, count: normalTabs))
        guard let firstnormalTab = tabManager.normalTabs[safe: 0],
              let secondnormalTab = tabManager.normalTabs[safe: 1],
              let thirdnormalTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Make the first tab the parent of the second tab
        secondnormalTab.parent = firstnormalTab

        // Make the parent tab staler than the others (not recent)
        firstnormalTab.lastExecutedTime = Date().dayBefore.toTimestamp()

        // Set the second tab as selected
        await MainActor.run {
            tabManager.selectTab(secondnormalTab)
        }

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, normalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondnormalTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondnormalTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdnormalTab, "Should select tab on the right since parent is stale")
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
        tabManager.normalTabs.forEach { tab in
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
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, we expect its recent parent to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
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
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed with no parent, we expect the right tab to be selected.
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
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
        tabManager.selectTab(secondPrivateTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)
        // Remove the selected tab
        tabManager.removeTab(secondPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the a middle tab is removed, and its parent is stale, we expect the tab on the right to be selected
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, thirdPrivateTab, "Should select tab on the right since parent is stale")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The third tab, now 2nd in array, should be selected")
    }

    @MainActor
    func testRemoveTab_removeLastPrivateTab_createsNewnormalTab() async throws {
        let numbernormalOlderLastMonthTabs = 1
        let numberPrivateTabs = 1
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let normalOlderLastMonthTabs = generateTabs(ofType: .normalOlderLastMonth, count: numbernormalOlderLastMonthTabs)

        let tabManager = createSubject(tabs: normalOlderLastMonthTabs + privateTabs)
        guard let privateTab = tabManager.privateTabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        tabManager.selectTab(privateTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numbernormalOlderLastMonthTabs + numberPrivateTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 3)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, privateTab)
        XCTAssertEqual(tabManager.selectedIndex, 3)

        // Remove the private tab, which is selected
        tabManager.removeTab(privateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last private tab is removed, we select the normal tab
        XCTAssertEqual(tabManager.tabs.count, numbernormalOlderLastMonthTabs + 1)
        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, privateTab, "The added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    @MainActor
    func testRemoveTab_removeLastPrivateTab_isOnlyTab_createsNewnormalTab() async throws {
        let numberPrivateTabs = 1
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let tabManager = createSubject(tabs: privateTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the private tab as selected
        tabManager.selectTab(firstTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last selected private tab
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there are no normal tabs,
        // we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    @MainActor
    func testRemoveTab_removeLastPrivateTab_onlyOtherTabsAreNormalTabs_createsNewNormalTab() async throws {
        let numberPrivateTabs = 1
        let numberInactiveTabs = 3
        let privateTabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let normalOlderLastMonthTabs = generateTabs(ofType: .normalOlderLastMonth, count: numberInactiveTabs)

        let tabManager = createSubject(tabs: privateTabs + normalOlderLastMonthTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        let initialTabs = tabManager.tabs

        // Set the private tab as selected
        tabManager.selectTab(firstTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs + numberInactiveTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last selected private tab
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected private tab is removed, and there are no only inactive normal tabs remaining,
        // we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberPrivateTabs + numberInactiveTabs, "Removed tab is replaced, count same")
        XCTAssertEqual(tabManager.normalTabs.count, 1, "A new active tab should be added")
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        for tab in initialTabs {
            XCTAssertNotEqual(tabManager.selectedTab, tab, "None of the initial tabs should be selected")
        }
        XCTAssertEqual(tabManager.selectedIndex, 3, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing last normal active tab)

    @MainActor
    func testRemoveTab_removeLastNormalTab_isOnlyTab_createsNewNormalTab() async throws {
        let numberNormalTabs = 1
        let normalTabs = generateTabs(ofType: .normal, count: numberNormalTabs)

        let tabManager = createSubject(tabs: normalTabs)
        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        tabManager.selectTab(firstTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last tab, which is active and selected
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last active tab is removed, we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, numberNormalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    @MainActor
    func testRemoveTab_removeLastNormalTab_createsNewnormalTab() async throws {
        let numbernormalOlderLastMonthTabs = 3
        let numberNormalTabsCount = 1
        let normalTabs = generateTabs(ofType: .normal, count: numberNormalTabsCount)
        let normalOlderLastMonthTabs = generateTabs(ofType: .normalOlderLastMonth, count: numbernormalOlderLastMonthTabs)

        let tabManager = createSubject(tabs: normalOlderLastMonthTabs + normalTabs)
        guard let activeTab = tabManager.normalTabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        tabManager.selectTab(activeTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numbernormalOlderLastMonthTabs + numberNormalTabsCount)
        XCTAssertEqual(tabManager.normalTabs.count, numberNormalTabsCount)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, activeTab)
        XCTAssertEqual(tabManager.selectedIndex, 3)

        // Remove the only active tab, which is selected
        tabManager.removeTab(activeTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last normal active tab is removed, even if there are normal active tabs, we expect a new normal active
        // tab to be added as we don't want to surface an old inactive tab.
        XCTAssertEqual(tabManager.tabs.count, numbernormalOlderLastMonthTabs + 1)
        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, activeTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 3, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing last normal inactive tab, which means it's selected, another weird edge case)

    @MainActor
    func testRemoveTab_removeLastnormalOlderLastMonthTab_isOnlyTab_createsNewnormalTab() async throws {
        let numberInactiveTabs = 1
        let inactiveTabs = generateTabs(ofType: .normalOlderLastMonth, count: numberInactiveTabs)
        let tabManager = createSubject(tabs: inactiveTabs)

        guard let firstTab = tabManager.tabs[safe: 0] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first tab as selected
        tabManager.selectTab(firstTab)
        // Selecting a tab makes it active, so reset to inactive again with an old timestamp
        firstTab.lastExecutedTime = Date().lastMonth.toTimestamp()

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 0)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstTab)
        XCTAssertEqual(tabManager.selectedIndex, 0)

        // Remove the last tab, which is inactive and selected
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // When the last selected inactive tab is removed, we expect a new active normal tab to be added
        XCTAssertEqual(tabManager.tabs.count, numberInactiveTabs)
        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, firstTab, "The newly added selected tab should not equal the removed tab")
        XCTAssertEqual(tabManager.selectedIndex, 0, "A new tab should be appended and selected")
    }

    // MARK: - Remove Tab (removing one unselected tabs among many)

    @MainActor
    func testRemoveTab_removeUnselectednormalTab_fromManyMixedTabs_causesArrayShift() async throws {
        let numbernormalOlderLastMonthTabs = 3
        let normalTabs = 3
        let totalTabCount = numbernormalOlderLastMonthTabs + normalTabs
        // Mix up the normal active and inactive tabs in the `tabs` array
        let normalOlderLastMonth = generateTabs(ofType: .normalOlderLastMonth, count: 1)
        let normal = generateTabs(ofType: .normal, count: 2)
        let normalOlderLastMonth2 = generateTabs(ofType: .normalOlderLastMonth, count: 2)
        let normal2 = generateTabs(ofType: .normal, count: 1)

        let tabManager = createSubject(tabs: normalOlderLastMonth + normal + normalOlderLastMonth2 + normal2)

        guard let firstnormalTab = tabManager.normalTabs[safe: 0],
              let thirdnormalTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 3rd normal active tab as selected
        tabManager.selectTab(thirdnormalTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdnormalTab)
        XCTAssertEqual(tabManager.selectedIndex, 5)

        // Remove the unselected normal active tab at an index smaller than the selected tab to cause an array shift for the
        // selected tab
        tabManager.removeTab(firstnormalTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, thirdnormalTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 4, "The selected tab index should have shifted left")
    }

    @MainActor
    func testRemoveTab_removeUnselectednormalTab_fromManyMixedTabs_noArrayShift() async throws {
        let numbernormalOlderLastMonthTabs = 3
        let normalTabs = 3
        let totalTabCount = numbernormalOlderLastMonthTabs + normalTabs
        // Mix up the normal active and inactive tabs in the `tabs` array
        let normalOlderLastMonth1 = generateTabs(ofType: .normalOlderLastMonth, count: 1)
        let normal1 = generateTabs(ofType: .normal, count: 2)
        let normalOlderLastMonth2 = generateTabs(ofType: .normalOlderLastMonth, count: 2)
        let normal2 = generateTabs(ofType: .normal, count: 1)

        let tabManager = createSubject(tabs: normalOlderLastMonth1 + normal1 + normalOlderLastMonth2 + normal2)

        guard let firstnormalTab = tabManager.normalTabs[safe: 0],
              let thirdnormalTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 1st normal active tab as selected
        tabManager.selectTab(firstnormalTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstnormalTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // Remove the unselected normal active tab at an index larger than the selected tab so no array shift is necessary
        // for the selected tab
        tabManager.removeTab(thirdnormalTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, firstnormalTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 1, "The selected tab index should not have shifted")
    }

    @MainActor
    func testRemoveTab_removeUnselectedPrivateTab_fromManyMixedTabs_causesArrayShift() async throws {
        let numbernormalOlderLastMonthTabs = 3
        let normalTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numbernormalOlderLastMonthTabs + numberPrivateTabs + normalTabs
        let normalOlderLastMonth = generateTabs(ofType: .normalOlderLastMonth, count: numbernormalOlderLastMonthTabs)
        let normal = generateTabs(ofType: .normal, count: normalTabs)
        let privateAny = generateTabs(ofType: .privateAny, count: numberPrivateTabs)

        let tabManager = createSubject(tabs: normalOlderLastMonth + normal + privateAny)

        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let secondPrivateTab = tabManager.privateTabs[safe: 1] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the 2nd private tab as selected (will cause a shift when the 1st private tab is deleted)
        tabManager.selectTab(secondPrivateTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 7)

        // Remove the unselected private tab at an index smaller than the selected tab to cause an array shift for the
        // selected tab
        tabManager.removeTab(firstPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, secondPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 6, "The selected tab index should have shifted left")
    }

    @MainActor
    func testRemoveTab_removeUnselectedPrivateTab_fromManyMixedTabs_noArrayShift() async throws {
        let numbernormalOlderLastMonthTabs = 3
        let normalTabs = 3
        let numberPrivateTabs = 3
        let totalTabCount = numbernormalOlderLastMonthTabs + numberPrivateTabs + normalTabs
        let normalOlderLastMonth = generateTabs(ofType: .normalOlderLastMonth, count: numbernormalOlderLastMonthTabs)
        let normal = generateTabs(ofType: .normal, count: normalTabs)
        let privateAny = generateTabs(ofType: .privateAny, count: numberPrivateTabs)

        let tabManager = createSubject(tabs: normalOlderLastMonth + normal + privateAny)

        guard let firstPrivateTab = tabManager.privateTabs[safe: 0],
              let thirdPrivateTab = tabManager.privateTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the first private tab as selected
        tabManager.selectTab(firstPrivateTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, totalTabCount)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab)
        XCTAssertEqual(tabManager.selectedIndex, 6)

        // Remove the unselected private tab at an index larger than the selected private tab so no array shift is necessary
        // for the selected tab
        tabManager.removeTab(thirdPrivateTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, totalTabCount - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs - 1)
        XCTAssertEqual(tabManager.selectedTab, firstPrivateTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 6, "The selected tab index should have shifted left")
    }

    // MARK: - Remove Tab (removing unselected tabs at array bounds)

    @MainActor
    func testRemoveTab_removeFirstTab_removeLastTime_removeOnlyTab() async throws {
        let normalTabs = 3
        let tabs = generateTabs(ofType: .normal, count: normalTabs)

        let tabManager = createSubject(tabs: tabs)

        guard let firstTab = tabManager.normalTabs[safe: 0],
              let secondTab = tabManager.normalTabs[safe: 1],
              let thirdTab = tabManager.normalTabs[safe: 2] else {
            XCTFail("Test did not meet preconditions")
            return
        }

        // Set the second tab as selected
        tabManager.selectTab(secondTab)

        // Sanity check preconditions
        XCTAssertEqual(tabManager.tabs.count, normalTabs)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab)
        XCTAssertEqual(tabManager.selectedIndex, 1)

        // [1] First, remove the tab at index 0
        tabManager.removeTab(firstTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should have shifted left")

        // [2] Second, remove the tab at count - 1 (last tab)
        tabManager.removeTab(thirdTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(tabManager.tabs.count, normalTabs - 2)
        XCTAssertEqual(tabManager.normalTabs.count, normalTabs - 2)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertEqual(tabManager.selectedTab, secondTab, "The selected tab should not change")
        XCTAssertEqual(tabManager.selectedIndex, 0, "The selected tab index should not change")

        // [3] Finally, remove the only tab (which is also the selected tab)
        tabManager.removeTab(secondTab.tabUUID)
        try await Task.sleep(nanoseconds: sleepTime)

        // We expect a new normal active tab will be created
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertEqual(tabManager.normalTabs.count, 1)
        XCTAssertEqual(tabManager.privateTabs.count, 0)
        XCTAssertNotEqual(tabManager.selectedTab, secondTab, "This tab should have been removed")
        XCTAssertEqual(tabManager.selectedIndex, 0, "Index of new normal active tab")
    }

    // MARK: - Remove Tabs Older than

    @MainActor
    func testRemoveNormalTabsOlderThan_whenNotOldNormalTabs_thenNoTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normal, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, numberTabs)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenInactiveNormalTabs_thenTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlderLastMonth, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneWeek, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 0)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenPrivateTabs_thenNoTabsRemoved() {
        let numberPrivateTabs = 3
        let tabs = generateTabs(ofType: .privateAny, count: numberPrivateTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.privateTabs.count, numberPrivateTabs)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenYesterdayNormalTabs_thenTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlderYesterday, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 0)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenYesterdayNormalTabsOlderThanOneWeek_thenTabsNotRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlderYesterday, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneWeek, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, numberTabs)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_whenYesterdayNormalTabsOlderThanOneMonth_thenTabsNotRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlderYesterday, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneMonth, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, numberTabs)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_when2WeeksNormalTabs_thenTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlder2Weeks, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 0)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_when2WeeksNormalTabsOlderThanOneWeek_thenTabsRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlder2Weeks, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneWeek, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 0)
    }

    @MainActor
    func testRemoveNormalTabsOlderThan_when2WeeksNormalTabsOlderThanOneMonth_thenTabsNotRemoved() {
        let numberTabs = 3
        let tabs = generateTabs(ofType: .normalOlder2Weeks, count: numberTabs)
        let tabManager = createSubject(tabs: tabs)

        tabManager.removeNormalTabsOlderThan(period: .oneMonth, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, numberTabs)
    }

    @MainActor
    func testRemoveNormalsTabsOlderThan_whenSelectedTabIsInTheMiddle_thenOrderIsProper() {
        let inactiveTabs1 = generateTabs(ofType: .normalInactive2Weeks, count: 10)
        let normalTabs = generateTabs(ofType: .normalActive, count: 3)
        let inactiveTabs2 = generateTabs(ofType: .normalInactive2Weeks, count: 10)
        let tabManager = createSubject(tabs: inactiveTabs1 + normalTabs + inactiveTabs2)
        tabManager.selectTab(normalTabs[safe: 0])

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 3)
        XCTAssertEqual(tabManager.selectedIndex, 0)
    }

    @MainActor
    func testRemoveNormalsTabsOlderThan_whenSelectedTabIsLast_thenOrderIsProper() {
        let inactiveTabs1 = generateTabs(ofType: .normalInactive2Weeks, count: 10)
        let normalTabs = generateTabs(ofType: .normalActive, count: 3)
        let tabManager = createSubject(tabs: inactiveTabs1 + normalTabs)
        tabManager.selectTab(normalTabs[safe: 2])

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 3)
        XCTAssertEqual(tabManager.selectedIndex, 2)
    }

    @MainActor
    func testRemoveNormalsTabsOlderThan_whenSelectedTabIsFirst_thenOrderIsProper() {
        let inactiveTabs1 = generateTabs(ofType: .normalInactive2Weeks, count: 10)
        let normalTabs = generateTabs(ofType: .normalActive, count: 3)
        let tabManager = createSubject(tabs: normalTabs + inactiveTabs1)
        tabManager.selectTab(normalTabs[safe: 0])

        tabManager.removeNormalTabsOlderThan(period: .oneDay, currentDate: testDate)

        XCTAssertEqual(tabManager.normalTabs.count, 3)
        XCTAssertEqual(tabManager.selectedIndex, 0)
    }

    // MARK: - Helper methods
    @MainActor
    private func createSubject(tabs: [Tab] = [],
                               windowUUID: WindowUUID? = nil,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabManagerImplementation {
        let subject = TabManagerImplementation(
            profile: mockProfile,
            imageStore: mockDiskImageStore,
            uuid: ReservedWindowUUID(uuid: windowUUID ?? tabWindowUUID, isNew: false),
            tabDataStore: mockTabStore,
            tabSessionStore: mockSessionStore,
            tabs: tabs
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func setIsDeeplinkOptimizationRefactorEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.deeplinkOptimizationRefactorFeature.with { _, _ in
            return DeeplinkOptimizationRefactorFeature(enabled: enabled)
        }
    }

    enum TabType {
        case normal
        case normalOlderLastMonth
        case normalOlder2Weeks
        case normalOlderYesterday
        case privateAny // `private` alone is a reserved compiler keyword
    }

    @MainActor
    private func generateTabs(ofType type: TabType = .normal, count: Int) -> [Tab] {
        var tabs = [Tab]()
        for i in 0..<count {
            let tab: Tab

            switch type {
            case .normal:
                tab = Tab(profile: mockProfile, windowUUID: tabWindowUUID)
            case .normalOlderLastMonth:
                let lastMonthDate = testDate.lastMonth
                tab = Tab(profile: MockProfile(), windowUUID: tabWindowUUID, tabCreatedTime: lastMonthDate)
            case .privateAny:
                tab = Tab(profile: mockProfile, isPrivate: true, windowUUID: tabWindowUUID)
            case .normalOlder2Weeks:
                let twoWeeksDate = testDate.lastTwoWeek
                tab = Tab(profile: MockProfile(), windowUUID: tabWindowUUID, tabCreatedTime: twoWeeksDate)
            case .normalOlderYesterday:
                let yesterdayDate = testDate.dayBefore
                tab = Tab(profile: MockProfile(), windowUUID: tabWindowUUID, tabCreatedTime: yesterdayDate)
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
                              temporaryDocumentSession: [:])
            tabData.append(tab)
        }
        return tabData
    }

    /// Generate a test URL given a count that is used as query parameter to get diversified URLs
    private func testURL(count: Int) -> URL {
        return URL(string: "https://mozilla.com?item=\(count)")!
    }

    @MainActor
    private func setupForFindRightOrLeftTab_mixedTypes(file: StaticString = #filePath,
                                                       line: UInt = #line) -> TabManagerImplementation {
        // Set up a tab array as follows:
        // [N1, P1, P2, N2, N3, N4, N5, N6, P3]
        //   0   1   2   3   4   5   6   7   8
        let tabs1 = generateTabs(ofType: .normal, count: 1)
        let tabs2 = generateTabs(ofType: .privateAny, count: 2)
        let tabs3to5 = generateTabs(ofType: .normalOlderLastMonth, count: 3)
        let tabs6to7 = generateTabs(ofType: .normal, count: 2)
        let tabs8 = generateTabs(ofType: .privateAny, count: 1)

        let tabManager = createSubject(tabs: tabs1 + tabs2 + tabs3to5 + tabs6to7 + tabs8)
        // Check preconditions
        XCTAssertEqual(tabManager.tabs.count, 9, file: file, line: line)
        XCTAssertEqual(tabManager.normalTabs.count, 6, file: file, line: line)
        XCTAssertEqual(tabManager.privateTabs.count, 3, file: file, line: line)
        return tabManager
    }

    private func setupNimbusTabTrayUIExperimentTesting(isEnabled: Bool) {
        FxNimbus.shared.features.tabTrayUiExperiments.with { _, _ in
            return TabTrayUiExperiments(
                enabled: isEnabled
            )
        }
    }
}

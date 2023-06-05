// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Shared
import Storage
import UIKit
import WebKit
import Common

import XCTest

open class TabManagerMockProfile: MockProfile {
    var numberOfTabsStored = 0
    override public func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        numberOfTabsStored = tabs.count
        return deferMaybe(tabs.count)
    }
}

struct MethodSpy {
    let functionName: String
    let method: ((_ tabs: [Tab?]) -> Void)?
    let file: StaticString
    let line: UInt

    init(functionName: String, file: StaticString = #file, line: UInt = #line) {
        self.functionName = functionName
        self.method = nil
        self.file = file
        self.line = line
    }

    init(functionName: String, file: StaticString = #file, line: UInt = #line, method: ((_ tabs: [Tab?]) -> Void)?) {
        self.functionName = functionName
        self.method = method
        self.file = file
        self.line = line
    }
}

private let spyDidSelectedTabChange = "tabManager(_:didSelectedTabChange:previous:isRestoring:)"

open class MockTabManagerDelegate: TabManagerDelegate {
    // This array represents the order in which delegate methods should be called.
    // each delegate method will pop the first struct from the array. If the method
    // name doesn't match the struct then the order is incorrect, then it evaluates
    // the method closure which will return true/false depending on if the tabs are correct.
    var methodCatchers: [MethodSpy] = []

    func expect(_ methods: [MethodSpy]) {
        self.methodCatchers.append(contentsOf: methods)
    }

    func verify(_ message: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(methodCatchers.isEmpty, message, file: file, line: line)
    }

    func testDelegateMethodWithName(_ name: String, tabs: [Tab?], file: StaticString = #file, line: UInt = #line) {
        guard let spy = self.methodCatchers.first else {
            XCTFail("No method was available in the queue. For the delegate method \(name) to use", file: file, line: line)
            return
        }

        XCTAssertEqual(spy.functionName, name, file: spy.file, line: spy.line)
        if let methodCheck = spy.method, spy.functionName == name {
            methodCheck(tabs)
        } else if spy.functionName != name {
            XCTFail("Spy function name \(spy.functionName) didn't had the same name as the first element in the queue \(name)", file: spy.file, line: spy.line)
        }
        methodCatchers.removeFirst()
    }

    public func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {
        testDelegateMethodWithName(#function, tabs: [selected, previous])
    }

    public func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {
        testDelegateMethodWithName(#function, tabs: [tab])
    }

    public func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        testDelegateMethodWithName(#function, tabs: [tab])
    }

    public func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        testDelegateMethodWithName(#function, tabs: [])
    }

    public func tabManagerDidAddTabs(_ tabManager: TabManager) {
        testDelegateMethodWithName(#function, tabs: [])
    }

    public func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        testDelegateMethodWithName(#function, tabs: [])
    }
}

class LegacyTabManagerTests: XCTestCase {
    let didRemove = MethodSpy(functionName: "tabManager(_:didRemoveTab:isRestoring:)")
    let didAdd = MethodSpy(functionName: "tabManager(_:didAddTab:placeNextToParentTab:isRestoring:)")
    let didSelect = MethodSpy(functionName: spyDidSelectedTabChange)
    let didRemoveAllTabs = MethodSpy(functionName: "tabManagerDidRemoveAllTabs(_:toast:)")

    var profile: TabManagerMockProfile!
    var manager: LegacyTabManager!
    var delegate: MockTabManagerDelegate!

    override func setUp() {
        super.setUp()

        profile = TabManagerMockProfile()
        manager = LegacyTabManager(profile: profile, imageStore: nil)
        delegate = MockTabManagerDelegate()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        delegate.verify("Not all delegate methods were called")

        profile.shutdown()
        manager.removeDelegate(delegate) {
            self.manager.testRemoveAll()
        }

        super.tearDown()
    }

    func testAddTabShouldAddOneNormalTab() {
        manager.addDelegate(delegate)
        delegate.expect([didAdd])
        manager.addTab()

        XCTAssertEqual(manager.normalTabs.count, 1, "There should be one normal tab")
        XCTAssertEqual(manager.tabs.count, 1, "There should be one tab")
    }

    func testAddTabShouldAddOnePrivateTab() {
        manager.addDelegate(delegate)
        delegate.expect([didAdd])
        manager.addTab(isPrivate: true)
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be one private tab")
        XCTAssertEqual(manager.tabs.count, 1, "There should be one tab")
    }

    func testAddTabAndSelect() {
        manager.addDelegate(delegate)
        delegate.expect([didAdd, didSelect])
        manager.selectTab(manager.addTab())
        XCTAssertEqual(manager.selectedIndex, 0, "There should be selected first tab")
    }

    func testAddTwoTabs_moveTabFromLastToFirstPosition() {
        manager.addDelegate(delegate)
        // Add two tabs, last one will be selected
        delegate.expect([didAdd, didAdd, didSelect])
        manager.addTab()
        manager.selectTab(manager.addTab())
        XCTAssertEqual(manager.tabs.count, 2, "There should be two tabs")

        manager.moveTab(isPrivate: false, fromIndex: 1, toIndex: 0)
        XCTAssertEqual(manager.selectedIndex, 0, "Second tab should be selected")
    }

    func testAddTwoTabs_selectWithoutPrevious() {
        manager.addDelegate(delegate)
        let didSelectSecond = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            XCTAssertNotNil(tabs[0]) // Selected
            XCTAssertNil(tabs[1]) // Previous
        }
        delegate.expect([didAdd, didAdd, didSelectSecond])

        manager.addTab()
        let tab = manager.addTab()
        XCTAssertEqual(manager.tabs.count, 2, "There should be two tabs")

        manager.selectTab(tab)
        XCTAssertEqual(manager.selectedTab, tab, "Tab should be selected")
    }

    func testAddTwoTabs_selectFirstThenSelectSecond_previousIsntNil() {
        manager.addDelegate(delegate)
        let didSelectSecond = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            XCTAssertNotNil(tabs[0]) // Selected
            XCTAssertNotNil(tabs[1]) // Previous
        }
        delegate.expect([didAdd, didSelect, didAdd, didSelectSecond])

        let firstTab = manager.addTab()
        manager.selectTab(firstTab)

        let secondTab = manager.addTab()
        manager.selectTab(secondTab)
        XCTAssertEqual(manager.tabs.count, 2, "There should be two tabs")
    }

    func testAddTwoTabs_selectFirstThenSelectSecond_thenDeleteLastTab() {
        manager.addDelegate(delegate)
        // Calling didRemove adds a delegate call to didSelect here since we're removing the selected tab
        delegate.expect([didAdd, didSelect, didAdd, didSelect, didRemove, didSelect])

        let firstTab = manager.addTab()
        manager.selectTab(firstTab)
        let secondTab = manager.addTab()
        manager.selectTab(secondTab)
        XCTAssertEqual(manager.tabs.count, 2, "There should be two tabs")
        XCTAssertEqual(manager.selectedTab, secondTab, "Second tab should be selected")

        removeTabAndAssert(tab: secondTab) {
            XCTAssertEqual(self.manager.tabs.count, 1, "There should be one tabs")
            XCTAssertEqual(self.manager.selectedTab, firstTab, "First tab should be selected since second tab was removed")
        }
    }

    func testDidSelectPrivateTabAfterNormalTab() {
        manager.addDelegate(delegate)
        delegate.expect([didAdd, didSelect, didAdd])
        let tab = manager.addTab()
        manager.selectTab(tab)
        let privateTab = manager.addTab(isPrivate: true)

        let didSelectPrivate = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            let nextPrivate = tabs[0]!
            let previousNormal = tabs[1]!
            XCTAssertTrue(previousNormal != nextPrivate)
            XCTAssertTrue(nextPrivate == privateTab)
            XCTAssertTrue(nextPrivate.isPrivate)
            XCTAssertTrue(previousNormal == tab)
            XCTAssertFalse(previousNormal.isPrivate)
            XCTAssertTrue(self.manager.selectedTab == privateTab)
        }
        delegate.expect([didSelectPrivate])
        manager.selectTab(privateTab)
    }

    func testDidDeleteLastPrivateTab() {
        manager.addDelegate(delegate)
        // Calling didRemove adds a delegate call to didSelect here since we're removing the selected tab
        delegate.expect([didAdd, didSelect, didAdd, didSelect, didRemove, didSelect])
        let tab = manager.addTab()
        manager.selectTab(tab)
        let privateTab = manager.addTab(isPrivate: true)
        manager.selectTab(privateTab)
        removeTabAndAssert(tab: privateTab) {}
    }

    func testRemoveTabsRemovesAllTabs() {
        // This test makes sure that a normal tab is always added even when a normal tab is not selected when calling removeAll
        manager.addDelegate(delegate)

        delegate.expect([didAdd, didAdd, didSelect, didAdd, didSelect])
        manager.addTab()
        let tab = manager.addTab()
        manager.selectTab(tab)
        let privateTab = manager.addTab(isPrivate: true)
        manager.selectTab(privateTab)
        XCTAssertEqual(manager.normalTabs.count, 2, "There should be two normal tabs")
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be one private tab")

        delegate.expect([didRemove, didRemove])
        manager.removeTabs(manager.normalTabs)
        XCTAssertEqual(manager.normalTabs.count, 0, "There should be no normal tab")
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be one private tab")
    }

    func testPrivatePreference_deletePrivateTabsOnExit() {
        profile.prefs.setBool(true, forKey: "settings.closePrivateTabs")

        // Create one private and one normal tab
        let tab = manager.addTab()
        manager.selectTab(tab)
        manager.selectTab(manager.addTab(isPrivate: true))

        XCTAssertEqual(manager.selectedTab?.isPrivate, true, "The selected tab should be the private tab")
        XCTAssertEqual(manager.privateTabs.count, 1, "There should only be one private tab")

        manager.selectTab(tab)
        XCTAssertEqual(manager.privateTabs.count, 0, "If the normal tab is selected the private tab should have been deleted")
        XCTAssertEqual(manager.normalTabs.count, 1, "The regular tab should stil be around")

        manager.selectTab(manager.addTab(isPrivate: true))
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be one new private tab")
        manager.willSwitchTabMode(leavingPBM: true)
        XCTAssertEqual(manager.privateTabs.count, 1, "After willSwitchTabMode there should be one private tab as we clear private tab on normal tab selection")

        manager.selectTab(manager.addTab(isPrivate: true))
        manager.selectTab(manager.addTab(isPrivate: true))
        XCTAssertEqual(manager.privateTabs.count, 3, "Private tabs should not be deleted when another one is added")
        manager.selectTab(manager.addTab())
        XCTAssertEqual(manager.privateTabs.count, 0, "But once we add a normal tab we've switched out of private mode. Private tabs should be deleted")
        XCTAssertEqual(manager.normalTabs.count, 2, "The original normal tab and the new one should both still exist")

        profile.prefs.setBool(false, forKey: "settings.closePrivateTabs")
        manager.selectTab(manager.addTab(isPrivate: true))
        manager.selectTab(tab)
        XCTAssertEqual(manager.selectedTab?.isPrivate, false, "The selected tab should not be private")
        XCTAssertEqual(manager.privateTabs.count, 1, "If the flag is false then private tabs should still exist")
    }

    func testPrivatePreference_togglePBMDeletesPrivate() {
        profile.prefs.setBool(true, forKey: "settings.closePrivateTabs")

        let tab = manager.addTab()
        manager.selectTab(tab)
        manager.selectTab(manager.addTab())

        manager.willSwitchTabMode(leavingPBM: false)
        manager.selectTab(manager.addTab(isPrivate: true))
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be 1 private tab")

        manager.willSwitchTabMode(leavingPBM: true)
        manager.selectTab(tab)
        XCTAssertEqual(manager.privateTabs.count, 0, "There should be 0 private tab")

        removeTabAndAssert(tab: tab) {
            XCTAssertEqual(self.manager.normalTabs.count, 1, "There should be 1 normal tab")
        }
    }

    func testRemoveNonSelectedTab() {
        let tab = manager.addTab()
        manager.selectTab(tab)
        manager.addTab()
        let deleteTab = manager.addTab()

        removeTabAndAssert(tab: deleteTab) {
            XCTAssertEqual(tab, self.manager.selectedTab)
            XCTAssertFalse(self.manager.tabs.contains(deleteTab))
        }
    }

    func testDeleteSelectedTab_ParentTabIfItWasMostRecentlyVisited() {
        func addTab(_ visit: Bool) -> Tab {
            let tab = manager.addTab()
            if visit {
                tab.lastExecutedTime = Date.now()
            }
            return tab
        }

        profile.prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.InactiveTabs)

        _ = addTab(false) // not visited
        let tab1 = addTab(true)
        _ = addTab(true)
        let tab3 = addTab(true)
        _ = addTab(false) // not visited

        // starting at tab1, we should be selecting
        // [ tab3, tab4, tab2, tab0 ]

        manager.selectTab(tab1)
        tab1.parent = tab3

        removeTabAndAssert(tab: manager.selectedTab!) {
            XCTAssertEqual(self.manager.selectedTab, tab3)
        }
    }

    func testDeleteSelectedTab_NextToTheRight() {
        func addTab(_ visit: Bool) -> Tab {
            let tab = manager.addTab()
            if visit {
                tab.lastExecutedTime = Date.now()
            }
            return tab
        }

        _ = addTab(false) // not visited
        _ = addTab(true)
        let tab3 = addTab(true)
        let tab4 = addTab(false) // not visited

        manager.selectTab(tab3)

        removeTabAndAssert(tab: manager.selectedTab!) {
            XCTAssertEqual(self.manager.selectedTab, tab4)
        }
    }

    func testDeleteSelectedTab_NextToTheLeftWhenNoneToTheRight() {
        func addTab(_ visit: Bool) -> Tab {
            let tab = manager.addTab()
            if visit {
                tab.lastExecutedTime = Date.now()
            }
            return tab
        }

        _ = addTab(false) // not visited
        let tab2 = addTab(true)
        let tab4 = addTab(false) // not visited

        manager.selectTab(tab4)

        removeTabAndAssert(tab: manager.selectedTab!) {
            XCTAssertEqual(self.manager.selectedTab, tab2)
        }
    }

    func testDeleteSelectedTab_LastOneLeft() {
        func addTab(_ visit: Bool) -> Tab {
            let tab = manager.addTab()
            if visit {
                tab.lastExecutedTime = Date.now()
            }
            return tab
        }

        let tab0 = addTab(false) // not visited
        let tab2 = addTab(true)

        manager.selectTab(tab2)

        removeTabAndAssert(tab: manager.selectedTab!) {
            XCTAssertEqual(self.manager.selectedTab, tab0)
        }
    }

    func testDeleteSelectedTab_InactiveTabsPresent() {
        func addTab(_ inactive: Bool) -> Tab {
            let tab = manager.addTab()
            if inactive {
                let currentDate = Date()
                let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate) ?? Date()
                let day15Old = Calendar.current.date(byAdding: .day, value: -15, to: noon) ?? Date()
                tab.lastExecutedTime = day15Old.toTimestamp()
            }
            return tab
        }

        _ = addTab(true) // inactive
        let tab1 = addTab(false) // active
        _ = addTab(true) // inactive
        let tab3 = addTab(false) // active
        _ = addTab(false) // active

        manager.selectTab(tab1)

        removeTabAndAssert(tab: manager.selectedTab!) {
            XCTAssertEqual(self.manager.selectedTab, tab3)
        }
    }

    func testDeleteLastTab_selectsThePrevious() {
        manager.addDelegate(delegate)
        var methods = Array(repeating: didAdd, count: 10)
        methods.append(contentsOf: [didSelect])
        delegate.expect(methods)

        (0..<10).forEach { _ in manager.addTab() }
        manager.selectTab(manager.tabs.last)
        let deleteTab = manager.tabs.last
        let newSelectedTab = manager.tabs[8]

        let didSelectNew = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertEqual(deleteTab, previous)
            XCTAssertEqual(next, newSelectedTab)
        }
        delegate.expect([didRemove, didSelectNew])
        removeTabAndAssert(tab: manager.tabs.last!) {}
    }

    func testDelegatesCalledWhenRemovingPrivateTabs() {
        // Setup
        manager.addDelegate(delegate)
        profile.prefs.setBool(true, forKey: "settings.closePrivateTabs")
        delegate.expect([didAdd, didAdd, didSelect, didAdd, didSelect, didSelect])

        // Create one private and one normal tab
        let tab = manager.addTab()
        let newTab = manager.addTab()
        manager.selectTab(tab)
        manager.selectTab(manager.addTab(isPrivate: true))

        // Double check a few things
        XCTAssertEqual(manager.selectedTab?.isPrivate, true, "The selected tab should be the private tab")
        XCTAssertEqual(manager.privateTabs.count, 1, "There should only be one private tab")

        // switch to normal mode and select a normal tab
        // this will delete the private tabs due to close private tab settings
        manager.willSwitchTabMode(leavingPBM: true)
        manager.selectTab(tab)

        // make sure tabs are cleared properly and indexes are reset
        XCTAssertEqual(manager.privateTabs.count, 0, "Private tab should have been deleted")
        XCTAssertEqual(manager.selectedIndex, 0, "The selected index should have been reset")

        // didSelect should still be called when switching between a nil tab
        let didSelectNewTab = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            let next = tabs[0]!
            XCTAssertFalse(next.isPrivate)
        }

        // make sure delegate method is actually called
        delegate.expect([didSelectNewTab])

        // select the new tab to trigger the delegate methods
        manager.selectTab(newTab)
    }

    func testDeleteFirstTab() {
        manager.addDelegate(delegate)
        var methods = Array(repeating: didAdd, count: 10)
        methods.append(contentsOf: [didSelect])
        delegate.expect(methods)

        (0..<10).forEach { _ in manager.addTab() }
        manager.selectTab(manager.tabs.first)
        let deleteTab = manager.tabs.first
        let newSelectedTab = manager.tabs[1]
        XCTAssertEqual(manager.tabs.count, 10)

        let didSelect = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertEqual(deleteTab, previous)
            XCTAssertEqual(next, newSelectedTab)
        }
        delegate.expect([didRemove, didSelect])
        removeTabAndAssert(tab: manager.tabs.first!) {}
    }

    func testRemoveTabSelectedTabShouldChangeIndex() {
        let tab1 = manager.addTab()
        manager.addTab()
        let tab3 = manager.addTab()

        manager.selectTab(tab3)
        let beforeRemoveTabIndex = manager.selectedIndex
        removeTabAndAssert(tab: tab1) {
            XCTAssertNotEqual(self.manager.selectedIndex, beforeRemoveTabIndex)
            XCTAssertEqual(self.manager.selectedTab, tab3)
            XCTAssertEqual(self.manager.tabs[self.manager.selectedIndex], tab3)
        }
    }

    func testRemoveTabRemovingLastNormalTabShouldNotSwitchToPrivateTab() {
        let tab0 = manager.addTab()
        let tab1 = manager.addTab(isPrivate: true)

        manager.selectTab(tab0)
        // select private tab, so we are in privateMode
        manager.selectTab(tab1, previous: tab0)
        // if we are able to remove normal tab this means we are no longer in private mode
        removeTabAndAssert(tab: tab0) {
            // manager should creat new tab and select it
            XCTAssertNotEqual(self.manager.selectedTab, tab1)
            XCTAssertNotEqual(self.manager.selectedIndex, self.manager.tabs.firstIndex(of: tab1))
        }
    }

    func testRemoveAllShouldRemoveAllTabs() {
        let tab0 = manager.addTab()
        let tab1 = manager.addTab()

        manager.testRemoveAll()
        XCTAssert(nil == manager.tabs.firstIndex(of: tab0))
        XCTAssert(nil == manager.tabs.firstIndex(of: tab1))
    }

    // Private tabs and regular tabs are in the same tabs array.
    // Make sure that when a private tab is added inbetween regular tabs it isnt accidentally selected when removing a regular tab
    func testTabsIndex() {
        // We add 2 tabs. Then a private one before adding another normal tab and selecting it.
        // Make sure that when the last one is deleted we dont switch to the private tab
        let (_, _, privateOne, last) = (manager.addTab(), manager.addTab(), manager.addTab(isPrivate: true), manager.addTab())
        manager.selectTab(last)
        manager.addDelegate(delegate)

        let didSelect = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertEqual(last, previous)
            XCTAssert(next != privateOne && !next.isPrivate)
        }
        delegate.expect([didRemove, didSelect])
        removeTabAndAssert(tab: last) {}
    }

    func testRemoveTabAndUpdateSelectedIndexIsSelectedParentTabAfterRemoval() {
        func addTab(_ visit: Bool) -> Tab {
            let tab = manager.addTab()
            if visit {
                tab.lastExecutedTime = Date.now()
            }
            return tab
        }
        _ = addTab(false) // not visited
        let tab1 = addTab(true)
        _ = addTab(true)
        let tab3 = addTab(true)
        _ = addTab(false) // not visited

        manager.selectTab(tab1)
        tab1.parent = tab3
        removeTabAndAssert(tab: tab1) {
            XCTAssertEqual(self.manager.selectedTab, tab3)
        }
    }

    func testTabsIndexClosingFirst() {
        // We add 2 tabs. Then a private one before adding another normal tab and selecting the first.
        // Make sure that when the last one is deleted we dont switch to the private tab
        let deleted = manager.addTab()
        let newSelected = manager.addTab()
        manager.addTab(isPrivate: true)
        manager.addTab()
        manager.selectTab(manager.tabs.first)
        manager.addDelegate(delegate)

        let didSelect = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            let next = tabs[0]!
            let previous = tabs[1]!
            XCTAssertEqual(deleted, previous)
            XCTAssertEqual(next, newSelected)
        }
        delegate.expect([didRemove, didSelect])

        removeTabAndAssert(tab: manager.tabs.first!) {
            self.delegate.verify("Not all delegate methods were called")
        }
    }

    func testGetMostRecentHomePageTab_NilHomepage() {
        let urlTab = manager.addTab(URLRequest(url: URL(string: "https://test.com")!))
        manager.selectTab(urlTab)

        XCTAssertNil(manager.getMostRecentHomepageTab())
    }

    func testGetMostRecentHomePageTab_ExistingHomepage() {
        let homepageTab = manager.addTab()
        let urlTab = manager.addTab(URLRequest(url: URL(string: "https://test.com")!))
        manager.selectTab(homepageTab)
        manager.selectTab(urlTab)

        XCTAssertEqual(manager.getMostRecentHomepageTab(), homepageTab)
    }

    func testGetMostRecentHomePageTab_LastCreated() {
        let firstHomepageTab = manager.addTab()
        let secondHomepageTab = manager.addTab()
        manager.selectTab(firstHomepageTab)
        manager.selectTab(secondHomepageTab)

        XCTAssertEqual(manager.getMostRecentHomepageTab(), secondHomepageTab)
    }

    func testGetMostRecentHomePageTab_SelectingFirst() {
        let firstHomepageTab = manager.addTab()
        let secondHomepageTab = manager.addTab()
        manager.selectTab(firstHomepageTab)
        manager.selectTab(secondHomepageTab)
        manager.selectTab(firstHomepageTab)

        XCTAssertEqual(manager.getMostRecentHomepageTab(), firstHomepageTab)
    }

    func testGetMostRecentHomePageTab_LastPrivateCreated() {
        let firstHomepageTab = manager.addTab(nil, afterTab: nil, isPrivate: true)
        let secondHomepageTab = manager.addTab(nil, afterTab: nil, isPrivate: true)
        manager.selectTab(firstHomepageTab)
        manager.selectTab(secondHomepageTab)

        XCTAssertEqual(manager.getMostRecentHomepageTab(), secondHomepageTab)
    }

    func testGetMostRecentHomePageTab_FirstPrivateCreated() {
        let privateHomepageTab = manager.addTab(nil, afterTab: nil, isPrivate: true)
        let normalHomepageTab = manager.addTab()
        let privateUrlTab = manager.addTab(URLRequest(url: URL(string: "https://test.com")!), afterTab: nil, isPrivate: true)
        manager.selectTab(privateHomepageTab)
        manager.selectTab(normalHomepageTab)
        manager.selectTab(privateUrlTab)

        // Expected private homepage because last selected tab is private
        XCTAssertEqual(manager.getMostRecentHomepageTab(), privateHomepageTab)
    }
}

// MARK: - Helper methods
private extension LegacyTabManagerTests {
    func removeTabAndAssert(tab: Tab, completion: @escaping () -> Void) {
        let expectation = self.expectation(description: "Tab is removed")
        manager.removeTab(tab) {
            completion()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Add multiple tabs next to parent

    func testInsertMultipleTabsNextToParentTab_TopTabTray() {
        let manager = LegacyTabManager(profile: profile, imageStore: nil)
        manager.tabDisplayType = .TopTabTray

        let parentTab = manager.addTab()
        manager.selectTab(parentTab)

        let childTab1 = manager.addTab(afterTab: parentTab)
        let childTab2 = manager.addTab(afterTab: parentTab)
        let childTab3 = manager.addTab(afterTab: parentTab)

        // Expected Order:
        // parentTab, childTab3, childTab2, childTab1

        XCTAssertEqual(manager.tabs.count, 4)
        XCTAssertEqual(manager.tabs[0].tabUUID, parentTab.tabUUID)
        XCTAssertEqual(manager.tabs[1].tabUUID, childTab3.tabUUID)
        XCTAssertEqual(manager.tabs[2].tabUUID, childTab2.tabUUID)
        XCTAssertEqual(manager.tabs[3].tabUUID, childTab1.tabUUID)
    }

    func testInsertMultipleTabsNextToParentTab_TabGrid() {
        let manager = LegacyTabManager(profile: profile, imageStore: nil)
        manager.tabDisplayType = .TabGrid // <- default

        let parentTab = manager.addTab()
        manager.selectTab(parentTab)

        let childTab1 = manager.addTab(afterTab: parentTab)
        let childTab2 = manager.addTab(afterTab: parentTab)
        let childTab3 = manager.addTab(afterTab: parentTab)

        // Expected Order:
        // parentTab, childTab1, childTab2, childTab3

        XCTAssertEqual(manager.tabs.count, 4)
        XCTAssertEqual(manager.tabs[0].tabUUID, parentTab.tabUUID)
        XCTAssertEqual(manager.tabs[1].tabUUID, childTab1.tabUUID)
        XCTAssertEqual(manager.tabs[2].tabUUID, childTab2.tabUUID)
        XCTAssertEqual(manager.tabs[3].tabUUID, childTab3.tabUUID)
    }
}

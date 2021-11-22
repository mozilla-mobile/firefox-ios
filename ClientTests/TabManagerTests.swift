// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Shared
import Storage
import UIKit
import WebKit

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

fileprivate let spyDidSelectedTabChange = "tabManager(_:didSelectedTabChange:previous:isRestoring:)"

open class MockTabManagerDelegate: TabManagerDelegate {
    // This array represents the order in which delegate methods should be called.
    // each delegate method will pop the first struct from the array. If the method name doesn't match the struct then the order is incorrect
    // Then it evaluates the method closure which will return true/false depending on if the tabs are correct
    var methodCatchers: [MethodSpy] = []

    func expect(_ methods: [MethodSpy]) {
        self.methodCatchers.append(contentsOf: methods)
    }

    func verify(_ message: String) {
        XCTAssertTrue(methodCatchers.isEmpty, message)
    }

    func testDelegateMethodWithName(_ name: String, tabs: [Tab?]) {
        guard let spy = self.methodCatchers.first else {
            XCTFail("No method was available in the queue. For the delegate method \(name) to use")
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

class TabManagerTests: XCTestCase {

    let didRemove = MethodSpy(functionName: "tabManager(_:didRemoveTab:isRestoring:)")
    let didAdd = MethodSpy(functionName: "tabManager(_:didAddTab:placeNextToParentTab:isRestoring:)")
    let didSelect = MethodSpy(functionName: spyDidSelectedTabChange)
    let didRemoveAllTabs = MethodSpy(functionName: "tabManagerDidRemoveAllTabs(_:toast:)")

    var profile: TabManagerMockProfile!
    var manager: TabManager!
    var delegate: MockTabManagerDelegate!

    override func setUp() {
        super.setUp()

        profile = TabManagerMockProfile()
        manager = TabManager(profile: profile, imageStore: nil)
        delegate = MockTabManagerDelegate()
    }

    override func tearDown() {
        delegate.verify("Not all delegate methods were called")

        profile._shutdown()
        manager.removeDelegate(delegate)
        manager.removeAll()

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

        manager.removeTab(secondTab)
        XCTAssertEqual(manager.tabs.count, 1, "There should be one tabs")
        XCTAssertEqual(manager.selectedTab, firstTab, "First tab should be selected since second tab was removed")
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
        manager.removeTab(privateTab)
    }

    func testDidCreateNormalTabWhenDeletingAll() {
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

        // Function removeTabsWithToast calls didRemove for each tab removed, adds a normal tab and select it then calls didRemoveAllTabs
        delegate.expect([didRemove, didRemove, didAdd, didSelect, didRemoveAllTabs])
        manager.removeTabsWithToast(manager.normalTabs)
        XCTAssertEqual(manager.normalTabs.count, 1, "There should be one normal tab")
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be one private tab")
        XCTAssertFalse(manager.selectedTab!.isPrivate, "Selected tab should be normal tab")
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
        XCTAssertEqual(manager.privateTabs.count, 0, "After willSwitchTabMode there should be no more private tabs")

        manager.selectTab(manager.addTab(isPrivate: true))
        manager.selectTab(manager.addTab(isPrivate: true))
        XCTAssertEqual(manager.privateTabs.count, 2, "Private tabs should not be deleted when another one is added")
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
        manager.selectTab(manager.addTab(isPrivate: true))

        manager.willSwitchTabMode(leavingPBM: false)
        XCTAssertEqual(manager.privateTabs.count, 1, "There should be 1 private tab")
        manager.willSwitchTabMode(leavingPBM: true)
        XCTAssertEqual(manager.privateTabs.count, 0, "There should be 0 private tab")
        manager.removeTab(tab)
        XCTAssertEqual(manager.normalTabs.count, 1, "There should be 1 normal tab")
    }

    func testRemoveNonSelectedTab() {
        let tab = manager.addTab()
        manager.selectTab(tab)
        manager.addTab()
        let deleteTab = manager.addTab()

        manager.removeTab(deleteTab)
        XCTAssertEqual(tab, manager.selectedTab)
        XCTAssertFalse(manager.tabs.contains(deleteTab))
    }

    func testDeleteSelectedTab() {

        func addTab(_ visit: Bool) -> Tab {
            let tab = manager.addTab()
            if visit {
                tab.lastExecutedTime = Date.now()
            }
            return tab
        }

        let tab0 = addTab(false) // not visited
        let tab1 = addTab(true)
        let tab2 = addTab(true)
        let tab3 = addTab(true)
        let tab4 = addTab(false) // not visited

        // starting at tab1, we should be selecting
        // [ tab3, tab4, tab2, tab0 ]

        manager.selectTab(tab1)
        tab1.parent = tab3
        manager.removeTab(manager.selectedTab!)
        // Rule: parent tab if it was the most recently visited
        XCTAssertEqual(manager.selectedTab, tab3)

        manager.removeTab(manager.selectedTab!)
        // Rule: next to the right.
        XCTAssertEqual(manager.selectedTab, tab4)

        manager.removeTab(manager.selectedTab!)
        // Rule: next to the left, when none to the right
        XCTAssertEqual(manager.selectedTab, tab2)

        manager.removeTab(manager.selectedTab!)
        // Rule: last one left.
        XCTAssertEqual(manager.selectedTab, tab0)
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
        manager.removeTab(manager.tabs.last!)
    }

    func testDelegatesCalledWhenRemovingPrivateTabs() {
        // Setup
        manager.addDelegate(delegate)
        profile.prefs.setBool(true, forKey: "settings.closePrivateTabs")
        delegate.expect([didAdd, didAdd, didSelect, didAdd, didSelect])

        // Create one private and one normal tab
        let tab = manager.addTab()
        let newTab = manager.addTab()
        manager.selectTab(tab)
        manager.selectTab(manager.addTab(isPrivate: true))

        // Double check a few things
        XCTAssertEqual(manager.selectedTab?.isPrivate, true, "The selected tab should be the private tab")
        XCTAssertEqual(manager.privateTabs.count, 1, "There should only be one private tab")

        // switch to normal mode. Which should delete the private tabs
        manager.willSwitchTabMode(leavingPBM: true)

        // make sure tabs are cleared properly and indexes are reset
        XCTAssertEqual(manager.privateTabs.count, 0, "Private tab should have been deleted")
        XCTAssertEqual(manager.selectedIndex, -1, "The selected index should have been reset")

        // didSelect should still be called when switching between a nil tab
        let didSelectNewTab = MethodSpy(functionName: spyDidSelectedTabChange) { tabs in
            XCTAssertNil(tabs[1], "there should be no previous tab")
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
        manager.removeTab(manager.tabs.first!)
    }

    func testRemoveTabSelectedTabShouldChangeIndex() {

        let tab1 = manager.addTab()
        manager.addTab()
        let tab3 = manager.addTab()

        manager.selectTab(tab3)
        let beforeRemoveTabIndex = manager.selectedIndex
        manager.removeTab(tab1)

        XCTAssertNotEqual(manager.selectedIndex, beforeRemoveTabIndex)
        XCTAssertEqual(manager.selectedTab, tab3)
        XCTAssertEqual(manager.tabs[manager.selectedIndex], tab3)
    }

    func testRemoveTabRemovingLastNormalTabShouldNotSwitchToPrivateTab() {

        let tab0 = manager.addTab()
        let tab1 = manager.addTab(isPrivate: true)

        manager.selectTab(tab0)
        // select private tab, so we are in privateMode
        manager.selectTab(tab1, previous: tab0)
        // if we are able to remove normal tab this means we are no longer in private mode
        manager.removeTab(tab0)

        // manager should creat new tab and select it
        XCTAssertNotEqual(manager.selectedTab, tab1)
        XCTAssertNotEqual(manager.selectedIndex, manager.tabs.firstIndex(of: tab1))
    }

    func testRemoveAllShouldRemoveAllTabs() {

        let tab0 = manager.addTab()
        let tab1 = manager.addTab()

        manager.removeAll()
        XCTAssert(nil == manager.tabs.firstIndex(of: tab0))
        XCTAssert(nil == manager.tabs.firstIndex(of: tab1))
    }

    // Private tabs and regular tabs are in the same tabs array.
    // Make sure that when a private tab is added inbetween regular tabs it isnt accidently selected when removing a regular tab
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
        manager.removeTab(last)

    }

    func testRemoveTabAndUpdateSelectedIndexIsSelectedParentTabAfterRemoval() {

        func addTab(_ visit: Bool) -> Tab {
            let tab = manager.addTab()
            if visit {
                tab.lastExecutedTime = Date.now()
            }
            return tab
        }
        let _ = addTab(false) // not visited
        let tab1 = addTab(true)
        let _ = addTab(true)
        let tab3 = addTab(true)
        let _ = addTab(false) // not visited

        manager.selectTab(tab1)
        tab1.parent = tab3
        manager.removeTab(tab1)

        XCTAssertEqual(manager.selectedTab, tab3)
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
        manager.removeTab(manager.tabs.first!)
        delegate.verify("Not all delegate methods were called")
    }

    func testUndoCloseTabsRemovesAutomaticallyCreatedNonPrivateTab() {

        let tab = manager.addTab()
        let tabToSave = Tab(bvc: BrowserViewController.foregroundBVC(), configuration: WKWebViewConfiguration())
        tabToSave.sessionData = SessionData(currentPage: 0, urls: [URL(string: "url")!], lastUsedTime: Date.now())
        guard let savedTab = SavedTab(tab: tabToSave, isSelected: true) else {
            XCTFail("Failed to serialize tab")
            return
        }
        manager.recentlyClosedForUndo = [savedTab]
        manager.undoCloseTabs()
        XCTAssertNotEqual(manager.tabs.first, tab)
    }
}

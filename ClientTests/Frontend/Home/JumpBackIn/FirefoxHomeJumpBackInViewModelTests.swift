// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import XCTest
import WebKit

class FirefoxHomeJumpBackInViewModelTests: XCTestCase {
    var subject: FirefoxHomeJumpBackInViewModel!
    
    var mockBrowserProfile: MockBrowserProfile!
    var tabManager: TabManager!
    var mockBrowserBarViewDelegate: MockBrowserBarViewDelegate!
    
    var stubBrowserViewController: BrowserViewController!
    
    override func setUp() {
        super.setUp()
        
        mockBrowserProfile = MockBrowserProfile(
                localName: "",
                syncDelegate: nil,
                clear: false
        )
        tabManager = TabManager(profile: mockBrowserProfile, imageStore: nil)
        stubBrowserViewController = BrowserViewController(
                profile: mockBrowserProfile,
                tabManager: TabManager(profile: mockBrowserProfile, imageStore: nil)
        )
        mockBrowserBarViewDelegate = MockBrowserBarViewDelegate()
        
        subject = FirefoxHomeJumpBackInViewModel(
                isZeroSearch: false,
                profile: mockBrowserProfile,
                isPrivate: false,
                tabManager: tabManager
        )
        subject.browserBarViewDelegate = mockBrowserBarViewDelegate
    }
    
    func test_switchToGroup_noBrowserDelegate_doNothing() {
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        subject.browserBarViewDelegate = nil
        var completionDidRun = false
        subject.onTapGroup = { tab in
            completionDidRun = true
        }
        
        subject.switchTo(group: group)
        
        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertFalse(completionDidRun)
    }
    
    func test_switchToGroup_noGroupedItems_doNothing() {
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        mockBrowserBarViewDelegate.inOverlayMode = true
        var completionDidRun = false
        subject.onTapGroup = { tab in
            completionDidRun = true
        }
        
        subject.switchTo(group: group)
        
        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 1)
        XCTAssertFalse(completionDidRun)
    }
    
    func test_switchToGroup_notInOverlayMode_doNothing() {
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        mockBrowserBarViewDelegate.inOverlayMode = false
        var completionDidRun = false
        subject.onTapGroup = { tab in
            completionDidRun = true
        }
        
        subject.switchTo(group: group)
        
        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertFalse(completionDidRun)
    }
    
    func test_switchToGroup_callCompletionOnFirstGroupedItem() {
        let expectedTab = Tab(bvc: stubBrowserViewController, configuration: WKWebViewConfiguration())
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [expectedTab], timestamp: 0)
        mockBrowserBarViewDelegate.inOverlayMode = true
        var receivedTab: Tab?
        subject.onTapGroup = { tab in
            receivedTab = tab
        }
        
        subject.switchTo(group: group)
        
        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(expectedTab, receivedTab)
    }
    
    func test_switchToTab_noBrowserDelegate_doNothing() {
        let tab = Tab(bvc: stubBrowserViewController, configuration: WKWebViewConfiguration())
        subject.browserBarViewDelegate = nil
        
        subject.switchTo(tab: tab)
        
        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
    }
    
    func test_switchToTab_notInOverlayMode_doNothing() {
        let tab = Tab(bvc: stubBrowserViewController, configuration: WKWebViewConfiguration())
        mockBrowserBarViewDelegate.inOverlayMode = false
        
        subject.switchTo(tab: tab)
        
        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
    }
    
    func test_switchToTab_tabManagerSelectsTab() {
        let tab1 = Tab(bvc: stubBrowserViewController, configuration: WKWebViewConfiguration())
        tabManager.reAddTabs(
                tabsToAdd: [
                    Tab(bvc: stubBrowserViewController, configuration: WKWebViewConfiguration()),
                    Tab(bvc: stubBrowserViewController, configuration: WKWebViewConfiguration()),
                    tab1
                ],
                previousTabUUID: "some UUId"
        )
        mockBrowserBarViewDelegate.inOverlayMode = true
        
        subject.switchTo(tab: tab1)
        
        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(tabManager.selectedTab, tab1)
    }
}

class MockBrowserBarViewDelegate: BrowserBarViewDelegate {
    var inOverlayMode = false
    
    var leaveOverlayModeCount = 0
    
    func leaveOverlayMode(didCancel cancel: Bool) {
        leaveOverlayModeCount += 1
    }
}
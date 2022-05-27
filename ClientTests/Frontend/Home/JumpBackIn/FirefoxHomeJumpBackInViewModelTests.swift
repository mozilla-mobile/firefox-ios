// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import XCTest
import WebKit

class FirefoxHomeJumpBackInViewModelTests: XCTestCase {
    var subject: FirefoxHomeJumpBackInViewModel!

    var mockBrowserProfile: MockBrowserProfile!
    var mockTabManager: MockTabManager!

    var mockBrowserBarViewDelegate: MockBrowserBarViewDelegate!
    var stubBrowserViewController: BrowserViewController!

    override func setUp() {
        super.setUp()

        mockBrowserProfile = MockBrowserProfile(
            localName: "",
            syncDelegate: nil,
            clear: false
        )
        mockTabManager = MockTabManager()
        stubBrowserViewController = BrowserViewController(
            profile: mockBrowserProfile,
            tabManager: TabManager(profile: mockBrowserProfile, imageStore: nil)
        )
        mockBrowserBarViewDelegate = MockBrowserBarViewDelegate()

        subject = FirefoxHomeJumpBackInViewModel(
            isZeroSearch: false,
            profile: mockBrowserProfile,
            isPrivate: false,
            tabManager: mockTabManager
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
        let expectedTab = Tab(bvc: stubBrowserViewController)
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
        let expectedTab = Tab(bvc: stubBrowserViewController)
        subject.browserBarViewDelegate = nil

        subject.switchTo(tab: expectedTab)

        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertTrue(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_notInOverlayMode_doNothing() {
        let tab = Tab(bvc: stubBrowserViewController)
        mockBrowserBarViewDelegate.inOverlayMode = false

        subject.switchTo(tab: tab)

        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertTrue(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_tabManagerSelectsTab() {
        let tab1 = Tab(bvc: stubBrowserViewController)
        mockBrowserBarViewDelegate.inOverlayMode = true

        subject.switchTo(tab: tab1)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        guard mockTabManager.lastSelectedTabs.count > 0 else {
            XCTFail("No tabs were selected in mock tab manager.")
            return
        }
        XCTAssertEqual(mockTabManager.lastSelectedTabs[0], tab1)
    }

    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_max2() {
        subject.featureFlags.set(feature: .tabTrayGroups, to: false)
        let tab1 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox1.com")
        let tab2 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox2.com")
        let tab3 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
        let expectation = XCTestExpectation(description: "Main queue fires; updateJumpBackInData(completion:) is called.")

        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        guard subject.jumpBackInList.tabs.count > 0 else {
            XCTFail("Incorrect number of tabs in subject")
            return
        }
        XCTAssertEqual(subject.jumpBackInList.tabs[0], tab1)
        XCTAssertEqual(subject.jumpBackInList.tabs[1], tab2)
        XCTAssertFalse(subject.jumpBackInList.tabs.contains(tab3))
    }
}

class MockTabManager: TabManagerProtocol {
    var nextRecentlyAccessedNormalTabs = [Tab]()

    var recentlyAccessedNormalTabs: [Tab] {
        return nextRecentlyAccessedNormalTabs
    }

    var lastSelectedTabs = [Tab]()
    var lastSelectedPreviousTabs = [Tab]()

    func selectTab(_ tab: Tab?, previous: Tab?) {
        if let tab = tab {
            lastSelectedTabs.append(tab)
        }

        if let previous = previous {
            lastSelectedPreviousTabs.append(previous)
        }
    }
}

class MockBrowserBarViewDelegate: BrowserBarViewDelegate {
    var inOverlayMode = false

    var leaveOverlayModeCount = 0

    func leaveOverlayMode(didCancel cancel: Bool) {
        leaveOverlayModeCount += 1
    }
}

fileprivate extension Tab {
    convenience init(bvc: BrowserViewController, urlString: String? = "www.website.com") {
        self.init(bvc: bvc, configuration: WKWebViewConfiguration())

        if let urlString = urlString {
            url = URL(string: urlString)!
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import XCTest
import WebKit
import Storage

class FirefoxHomeJumpBackInViewModelTests: XCTestCase {
    var subject: JumpBackInViewModel!

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

        subject = JumpBackInViewModel(
            isZeroSearch: false,
            profile: mockBrowserProfile,
            isPrivate: false,
            tabManager: mockTabManager
        )
        subject.browserBarViewDelegate = mockBrowserBarViewDelegate
    }

    override func tearDown() {
        super.tearDown()
        stubBrowserViewController = nil
        mockBrowserBarViewDelegate = nil
        mockTabManager = nil
        mockBrowserProfile = nil
        subject = nil
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

    func test_switchToGroup_inOverlayMode_leavesOverlayMode() {
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

    func test_switchToTab_notInOverlayMode_switchTabs() {
        let tab = Tab(bvc: stubBrowserViewController)
        mockBrowserBarViewDelegate.inOverlayMode = false

        subject.switchTo(tab: tab)

        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertFalse(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_inOverlayMode_leaveOverlayMode() {
        let tab = Tab(bvc: stubBrowserViewController)
        mockBrowserBarViewDelegate.inOverlayMode = true

        subject.switchTo(tab: tab)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 1)
        XCTAssertFalse(mockTabManager.lastSelectedTabs.isEmpty)
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

    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_onIphoneLayout_has2() {
        subject.featureFlags.set(feature: .tabTrayGroups, to: false)
        let tab1 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox1.com")
        let tab2 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox2.com")
        let tab3 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
        let expectation = XCTestExpectation(description: "Main queue fires; updateJumpBackInData(completion:) is called.")

        // iPhone layout
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .compact
        trait.overridenVerticalSizeClass = .regular

        subject.updateData {
            // Refresh data for specific layout
            self.subject.refreshData(for: trait)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 2, "iPhone portrait has 2 tabs in it's jumpbackin layout")
        XCTAssertEqual(subject.jumpBackInList.tabs[0], tab1)
        XCTAssertEqual(subject.jumpBackInList.tabs[1], tab2)
        XCTAssertFalse(subject.jumpBackInList.tabs.contains(tab3))
    }

    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_oniPhoneLandscapeLayout_has3() {
        subject.featureFlags.set(feature: .tabTrayGroups, to: false)
        let tab1 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox1.com")
        let tab2 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox2.com")
        let tab3 = Tab(bvc: stubBrowserViewController, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
        let expectation = XCTestExpectation(description: "Main queue fires; updateJumpBackInData(completion:) is called.")

        // Ipad layout
        let trait = FakeTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular

        subject.updateData {
            // Refresh data for specific layout
            self.subject.refreshData(for: trait)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        guard subject.jumpBackInList.tabs.count > 0 else {
            XCTFail("Incorrect number of tabs in subject")
            return
        }

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 3, "iPhone landscape has 3 tabs in it's jumpbackin layout, up until 4")
        XCTAssertEqual(subject.jumpBackInList.tabs[0], tab1)
        XCTAssertEqual(subject.jumpBackInList.tabs[1], tab2)
        XCTAssertEqual(subject.jumpBackInList.tabs[2], tab3)
    }

    // MARK: Syncable Tabs

    func test_updateData_mostRecentTab_noSyncableAccount() {
        let profile = MockProfile()
        profile.hasSyncableAccountMock = false
        subject = JumpBackInViewModel(
            isZeroSearch: false,
            profile: profile,
            isPrivate: false,
            tabManager: mockTabManager
        )

        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(subject.mostRecentSyncedTab, "There should be no most recent tab")
    }

    func test_updateData_mostRecentTab_noCachedClients() {
        subject = JumpBackInViewModel(
            isZeroSearch: false,
            profile: MockProfile(),
            isPrivate: false,
            tabManager: mockTabManager
        )

        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(subject.mostRecentSyncedTab, "There should be no most recent tab")
    }

    func test_updateData_mostRecentTab_noDesktopClients() {
        let profile = MockProfile()
        profile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs(idRange: 1...2))]
        subject = JumpBackInViewModel(
            isZeroSearch: false,
            profile: profile,
            isPrivate: false,
            tabManager: mockTabManager
        )

        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(subject.mostRecentSyncedTab, "There should be no most recent tab")
    }

    func test_updateData_mostRecentTab_oneDesktopClient() {
        let profile = MockProfile()
        let remoteClient = remoteDesktopClient()
        let remoteTabs = remoteTabs(idRange: 1...3)
        profile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs)]
        subject = JumpBackInViewModel(
            isZeroSearch: false,
            profile: profile,
            isPrivate: false,
            tabManager: mockTabManager
        )

        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(subject.mostRecentSyncedTab?.client, remoteClient)
        XCTAssertEqual(subject.mostRecentSyncedTab?.tab, remoteTabs.last)
    }

    func test_updateData_mostRecentTab_multipleDesktopClients() {
        let profile = MockProfile()
        let remoteClient = remoteDesktopClient(name: "Fake Client 2")
        let remoteClientTabs = remoteTabs(idRange: 7...9)
        profile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(), tabs: remoteTabs(idRange: 1...5)),
                                     ClientAndTabs(client: remoteClient, tabs: remoteClientTabs)]
        subject = JumpBackInViewModel(
            isZeroSearch: false,
            profile: profile,
            isPrivate: false,
            tabManager: mockTabManager
        )

        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(subject.mostRecentSyncedTab?.client, remoteClient)
        XCTAssertEqual(subject.mostRecentSyncedTab?.tab, remoteClientTabs.last)
    }
}

extension FirefoxHomeJumpBackInViewModelTests {
    var remoteClient: RemoteClient {
        return RemoteClient(guid: nil,
                            name: "Fake client",
                            modified: 1,
                            type: nil,
                            formfactor: nil,
                            os: nil,
                            version: nil,
                            fxaDeviceId: nil)
    }

    func remoteDesktopClient(name: String = "Fake client") -> RemoteClient {
        return RemoteClient(guid: nil,
                            name: name,
                            modified: 1,
                            type: "desktop",
                            formfactor: nil,
                            os: nil,
                            version: nil,
                            fxaDeviceId: nil)
    }

    func remoteTabs(idRange: ClosedRange<Int> = 1...1) -> [RemoteTab] {
        var remoteTabs: [RemoteTab] = []

        for i in idRange {
            let tab = RemoteTab(clientGUID: String(i),
                                URL: URL(string: "www.mozilla.org")!,
                                title: "Mozilla \(i)",
                                history: [],
                                lastUsed: UInt64(i),
                                icon: nil)
            remoteTabs.append(tab)
        }
        return remoteTabs
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

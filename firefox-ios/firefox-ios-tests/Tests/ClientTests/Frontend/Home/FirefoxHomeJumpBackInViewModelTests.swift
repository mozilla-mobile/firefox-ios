// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import WebKit
import Storage
import Shared

class FirefoxHomeJumpBackInViewModelTests: XCTestCase {
    var subject: JumpBackInViewModel!

    var mockProfile: MockProfile!
    var mockTabManager: MockTabManager!

    var mockBrowserBarViewDelegate: MockBrowserBarViewDelegate!
    var stubBrowserViewController: BrowserViewController!

    override func setUp() {
        super.setUp()

        mockProfile = MockProfile()
        mockTabManager = MockTabManager()
        stubBrowserViewController = BrowserViewController(
            profile: mockProfile,
            tabManager: TabManager(profile: mockProfile, imageStore: nil)
        )
        mockBrowserBarViewDelegate = MockBrowserBarViewDelegate()

        subject = JumpBackInViewModel(
            isZeroSearch: false,
            profile: mockProfile,
            isPrivate: false,
            tabManager: mockTabManager
        )
        subject.browserBarViewDelegate = mockBrowserBarViewDelegate
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
        stubBrowserViewController = nil
        mockBrowserBarViewDelegate = nil
        mockTabManager = nil
        mockProfile = nil
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
        let expectedTab = createTab(profile: mockProfile)
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
        let expectedTab = createTab(profile: mockProfile)
        subject.browserBarViewDelegate = nil

        subject.switchTo(tab: expectedTab)

        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertTrue(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_notInOverlayMode_switchTabs() {
        let tab = createTab(profile: mockProfile)
        mockBrowserBarViewDelegate.inOverlayMode = false

        subject.switchTo(tab: tab)

        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertFalse(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_inOverlayMode_leaveOverlayMode() {
        let tab = createTab(profile: mockProfile)
        mockBrowserBarViewDelegate.inOverlayMode = true

        subject.switchTo(tab: tab)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 1)
        XCTAssertFalse(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_tabManagerSelectsTab() {
        let tab1 = createTab(profile: mockProfile)
        mockBrowserBarViewDelegate.inOverlayMode = true

        subject.switchTo(tab: tab1)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        guard !mockTabManager.lastSelectedTabs.isEmpty else {
            XCTFail("No tabs were selected in mock tab manager.")
            return
        }
        XCTAssertEqual(mockTabManager.lastSelectedTabs[0], tab1)
    }

    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_onIphoneLayout_noAccount_has2() {
        mockProfile.hasSyncableAccountMock = false
        subject.featureFlags.set(feature: .tabTrayGroups, to: false)
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
        let expectation = XCTestExpectation(
            description: "Main queue fires; updateJumpBackInData(completion:) is called."
        )

        // iPhone layout
        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .compact
        trait.overridenVerticalSizeClass = .regular

        subject.updateData {
            // get section layout calculated
            self.subject.updateSectionLayout(for: trait, isPortrait: true, device: .phone)
            // Refresh data for specific layout
            self.subject.refreshData(for: trait, device: .phone)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 2, "iPhone portrait has 2 tabs in it's jumpbackin layout")
        XCTAssertEqual(subject.jumpBackInList.tabs[0], tab1)
        XCTAssertEqual(subject.jumpBackInList.tabs[1], tab2)
        XCTAssertFalse(subject.jumpBackInList.tabs.contains(tab3))
    }

    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_onIphoneLayout_hasAccount_has1() {
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(),
                                                       tabs: remoteTabs(idRange: 1...3))]
        subject.featureFlags.set(feature: .tabTrayGroups, to: false)
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
        let expectation = XCTestExpectation(
            description: "Main queue fires; updateJumpBackInData(completion:) is called."
        )

        // iPhone layout
        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .compact
        trait.overridenVerticalSizeClass = .regular

        subject.updateData {
            // get section layout calculated
            self.subject.updateSectionLayout(for: trait, isPortrait: true, device: .phone)
            // Refresh data for specific layout
            self.subject.refreshData(for: trait, device: .phone)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 1, "iPhone portrait has 1 tab in it's jumpbackin layout")
        XCTAssertEqual(subject.jumpBackInList.tabs[0], tab1)
        XCTAssertFalse(subject.jumpBackInList.tabs.contains(tab2))
        XCTAssertFalse(subject.jumpBackInList.tabs.contains(tab3))
    }

    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_oniPhoneLandscapeLayout_noAccount_has3() {
        mockProfile.hasSyncableAccountMock = false
        subject.featureFlags.set(feature: .tabTrayGroups, to: false)
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
        let expectation = XCTestExpectation(
            description: "Main queue fires; updateJumpBackInData(completion:) is called."
        )

        // iPhone landscape layout
        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular

        subject.updateData {
            // get section layout calculated
            self.subject.updateSectionLayout(for: trait, isPortrait: false, device: .phone)
            // Refresh data for specific layout
            self.subject.refreshData(for: trait, device: .phone)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        guard !subject.jumpBackInList.tabs.isEmpty else {
            XCTFail("Incorrect number of tabs in subject")
            return
        }

        XCTAssertEqual(
            subject.jumpBackInList.tabs.count,
            3,
            "iPhone landscape has 3 tabs in it's jumpbackin layout, up until 4"
        )
        XCTAssertEqual(subject.jumpBackInList.tabs[0], tab1)
        XCTAssertEqual(subject.jumpBackInList.tabs[1], tab2)
        XCTAssertEqual(subject.jumpBackInList.tabs[2], tab3)
    }

    // swiftlint:disable line_length
    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_oniPhoneLandscapeLayout_hasAccount_has2() {
    // swiftlint:enable line_length
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(),
                                                       tabs: remoteTabs(idRange: 1...3))]
        subject.featureFlags.set(feature: .tabTrayGroups, to: false)
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
        let expectation = XCTestExpectation(
            description: "Main queue fires; updateJumpBackInData(completion:) is called."
        )

        // iPhone landscape layout
        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular

        subject.updateData {
            self.subject.updateSectionLayout(
                for: trait,
                isPortrait: false,
                device: .phone
            ) // get section layout calculated
            self.subject.refreshData(for: trait, device: .phone) // Refresh data for specific layout
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        guard !subject.jumpBackInList.tabs.isEmpty else {
            XCTFail("Incorrect number of tabs in subject")
            return
        }

        XCTAssertEqual(
            subject.jumpBackInList.tabs.count,
            2,
            "iPhone landscape has 2 tabs in it's jumpbackin layout, up until 2"
        )
        XCTAssertEqual(subject.jumpBackInList.tabs[0], tab1)
        XCTAssertEqual(subject.jumpBackInList.tabs[1], tab2)
        XCTAssertFalse(subject.jumpBackInList.tabs.contains(tab3))
    }

    // MARK: Syncable Tabs

    func test_updateData_mostRecentTab_noSyncableAccount() {
        mockProfile.hasSyncableAccountMock = false
        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(subject.mostRecentSyncedTab, "There should be no most recent tab")
    }

    func test_updateData_mostRecentTab_noCachedClients() {
        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(subject.mostRecentSyncedTab, "There should be no most recent tab")
    }

    func test_updateData_mostRecentTab_noDesktopClients() {
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs(idRange: 1...2))]
        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(subject.mostRecentSyncedTab, "There should be no most recent tab")
    }

    func test_updateData_mostRecentTab_oneDesktopClient() {
        let remoteClient = remoteDesktopClient()
        let remoteTabs = remoteTabs(idRange: 1...3)
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs)]

        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
        subject.updateData {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(subject.mostRecentSyncedTab?.client, remoteClient)
        XCTAssertEqual(subject.mostRecentSyncedTab?.tab, remoteTabs.last)
    }

    func test_updateData_mostRecentTab_multipleDesktopClients() {
        let remoteClient = remoteDesktopClient(name: "Fake Client 2")
        let remoteClientTabs = remoteTabs(idRange: 7...9)
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(), tabs: remoteTabs(idRange: 1...5)),
                                     ClientAndTabs(client: remoteClient, tabs: remoteClientTabs)]

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

        for index in idRange {
            let tab = RemoteTab(clientGUID: String(index),
                                URL: URL(string: "www.mozilla.org")!,
                                title: "Mozilla \(index)",
                                history: [],
                                lastUsed: UInt64(index),
                                icon: nil)
            remoteTabs.append(tab)
        }
        return remoteTabs
    }
}

class MockBrowserBarViewDelegate: BrowserBarViewDelegate {
    var inOverlayMode = false

    var leaveOverlayModeCount = 0

    func leaveOverlayMode(didCancel cancel: Bool) {
        leaveOverlayModeCount += 1
    }
}

extension FirefoxHomeJumpBackInViewModelTests {
    func createTab(profile: MockProfile,
                   configuration: WKWebViewConfiguration = WKWebViewConfiguration(),
                   urlString: String? = "www.website.com") -> Tab {
        let tab = Tab(profile: profile, configuration: configuration)

        if let urlString = urlString {
            tab.url = URL(string: urlString)!
        }
        return tab
    }
}

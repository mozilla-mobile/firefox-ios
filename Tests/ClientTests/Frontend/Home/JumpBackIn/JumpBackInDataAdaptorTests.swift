// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Storage
import XCTest
import WebKit

// NOTE:
// Tab groups not tested at the moment since it depends on RustPlaces concrete object.
// Need protocol to be able to fix this

class JumpBackInDataAdaptorTests: XCTestCase {

    var mockTabManager: MockTabManager!
    var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        mockTabManager = MockTabManager()

        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
        mockProfile = nil
        mockTabManager = nil
    }

    func testEmptyData_tabTrayGroupsDisabled() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        let subject = createSubject()
        let jumpBackIn = subject.getJumpBackInData()
        let synced = subject.getSyncedTabData()

        XCTAssertEqual(jumpBackIn.itemsToDisplay, 0)
        XCTAssertNil(synced)
    }

    func testCompactJumpBackIn_tabTrayGroupsDisabled_withMoreJumpBackInTabs() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        mockProfile.hasSyncableAccountMock = false
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]

        let subject = createSubject()
        subject.refreshData(maxItemToDisplay: 2)

        let jumpBackIn = subject.getJumpBackInData()
        XCTAssertEqual(jumpBackIn.tabs.count, 2, "iPhone portrait has 2 tabs in it's jumpbackin layout")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
        XCTAssertEqual(jumpBackIn.tabs[1], tab2)
        XCTAssertFalse(jumpBackIn.tabs.contains(tab3))
    }

    func testCompactJumpBackIn_tabTrayGroupsDisabled_withLessJumpBackInTabs() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        mockProfile.hasSyncableAccountMock = false
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1]

        let subject = createSubject()
        subject.refreshData(maxItemToDisplay: 2)

        let jumpBackIn = subject.getJumpBackInData()
        XCTAssertEqual(jumpBackIn.tabs.count, 1, "With a max of 2 items, only shows 1 item when only 1 is available")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
    }

    func testCompactJumpBackInAndSyncedTab_tabTrayGroupsDisabled_withMoreJumpBackInTabsAndRemoteTabs() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(),
                                                       tabs: remoteTabs(idRange: 1...3))]
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]

        let subject = createSubject()
        subject.refreshData(maxItemToDisplay: 1)

        let jumpBackIn = subject.getJumpBackInData()
        XCTAssertEqual(jumpBackIn.tabs.count, 1, "iPhone portrait has 1 tab in it's jumpbackin layout")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
        XCTAssertFalse(jumpBackIn.tabs.contains(tab2))
        XCTAssertFalse(jumpBackIn.tabs.contains(tab3))

        let syncTab = subject.getSyncedTabData()
        XCTAssertNotNil(syncTab, "iPhone portrait will show 1 sync tab")
    }

    func testRegularIphone_tabTrayGroupsDisabled() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]

        let subject = createSubject()
        subject.refreshData(maxItemToDisplay: 4)

        let jumpBackIn = subject.getJumpBackInData()
        XCTAssertEqual(jumpBackIn.tabs.count, 3, "iPhone landscape has 3 tabs in it's jumpbackin layout, up until 4")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
        XCTAssertEqual(jumpBackIn.tabs[1], tab2)
        XCTAssertEqual(jumpBackIn.tabs[2], tab3)

        let syncTab = subject.getSyncedTabData()
        XCTAssertNil(syncTab)
    }

    func testRegularWithSyncedTabIphone_tabTrayGroupsDisabled_withSyncTab() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(),
                                                       tabs: remoteTabs(idRange: 1...3))]

        let subject = createSubject()
        subject.refreshData(maxItemToDisplay: 2)

        let jumpBackIn = subject.getJumpBackInData()
        XCTAssertEqual(jumpBackIn.tabs.count, 2, "iPhone landscape has 2 tabs in it's jumpbackin layout, up until 2")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
        XCTAssertEqual(jumpBackIn.tabs[1], tab2)
        XCTAssertFalse(jumpBackIn.tabs.contains(tab3))

        let syncTab = subject.getSyncedTabData()
        XCTAssertNotNil(syncTab, "iPhone landscape will show 1 sync tab")
    }

    func testSyncTab_whenNoSyncTabsData_notReturned() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        let subject = createSubject()

        let syncTab = subject.getSyncedTabData()
        XCTAssertNil(syncTab, "No sync tab since there's no remote tabs")
    }

    func testSyncTab_whenNoSyncAccount_notReturned() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        mockProfile.hasSyncableAccountMock = false
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(),
                                                       tabs: remoteTabs(idRange: 1...3))]
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        let subject = createSubject()

        let syncTab = subject.getSyncedTabData()
        XCTAssertNil(syncTab, "No sync tab since hasSyncableAccount is off")
    }

    func testSyncTab_noDesktopClients_notReturned() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        mockProfile.hasSyncableAccountMock = false
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs(idRange: 1...2))]
        let subject = createSubject()

        let syncTab = subject.getSyncedTabData()
        XCTAssertNil(syncTab, "No sync tab since there's no desktop client")
    }

    func testSyncTab_oneDesktopClient_returned() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        let remoteClient = remoteDesktopClient()
        let remoteTabs = remoteTabs(idRange: 1...3)
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs)]

        let subject = createSubject()

        let syncTab = subject.getSyncedTabData()
        XCTAssertEqual(syncTab?.client.name, remoteClient.name)
        XCTAssertEqual(syncTab?.tab.title, remoteTabs.last?.title)
        XCTAssertEqual(syncTab?.tab.URL, remoteTabs.last?.URL)
    }

    func testSyncTab_multipleDesktopClients_returnsLast() {
        FeatureFlagsManager.shared.set(feature: .tabTrayGroups, to: false)
        let remoteClient = remoteDesktopClient(name: "Fake Client 2")
        let remoteClientTabs = remoteTabs(idRange: 7...9)
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(), tabs: remoteTabs(idRange: 1...5)),
                                         ClientAndTabs(client: remoteClient, tabs: remoteClientTabs)]

        let subject = createSubject()

        let syncTab = subject.getSyncedTabData()
        XCTAssertEqual(syncTab?.client.name, remoteClient.name)
        XCTAssertEqual(syncTab?.tab.title, remoteClientTabs.last?.title)
        XCTAssertEqual(syncTab?.tab.URL, remoteClientTabs.last?.URL)
    }
}

// MARK: Helpers
extension JumpBackInDataAdaptorTests {

    func createSubject(file: StaticString = #file, line: UInt = #line) -> JumpBackInDataAdaptorImplementation {
        let dispatchGroup = MockDispatchGroup()
        let dispatchQueue = MockDispatchQueue()
        let siteImageHelper = SiteImageHelperMock()
        let notificationCenter = SpyNotificationCenter()

        let subject = JumpBackInDataAdaptorImplementation(profile: mockProfile,
                                                          tabManager: mockTabManager,
                                                          siteImageHelper: siteImageHelper,
                                                          dispatchGroup: dispatchGroup,
                                                          mainQueue: dispatchQueue,
                                                          userInteractiveQueue: dispatchQueue,
                                                          notificationCenter: notificationCenter)

        trackForMemoryLeaks(subject, file: file, line: line)
        trackForMemoryLeaks(siteImageHelper, file: file, line: line)
        trackForMemoryLeaks(dispatchGroup, file: file, line: line)
        trackForMemoryLeaks(dispatchQueue, file: file, line: line)

        return subject
    }

    func createTab(profile: MockProfile,
                   configuration: WKWebViewConfiguration = WKWebViewConfiguration(),
                   urlString: String? = "www.website.com") -> Tab {
        let tab = Tab(profile: profile, configuration: configuration)

        if let urlString = urlString {
            tab.url = URL(string: urlString)!
        }
        return tab
    }

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

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Storage
import XCTest
import WebKit
import Common

final class JumpBackInDataAdaptorTests: XCTestCase {
    var mockTabManager: MockTabManager!
    var mockProfile: MockProfile!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        mockTabManager = MockTabManager()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
        mockProfile = nil
        mockTabManager = nil
    }

    func testEmptyData() async {
        let subject = createSubject()
        await loadNewData(for: subject)

        let recentTabs = await subject.getRecentTabData()
        let synced = await subject.getSyncedTabData()
        XCTAssertEqual(recentTabs.count, 0)
        XCTAssertNil(synced)
    }

    func testGetRecentTabs() async {
        mockTabManager = MockTabManager(recentlyAccessedNormalTabs: createTabs())
        mockProfile.hasSyncableAccountMock = false
        let subject = createSubject()
        await loadNewData(for: subject)

        let recentTabs = await subject.getRecentTabData()
        XCTAssertEqual(recentTabs.count, 3)
    }

    func testGetRecentTabsAndSyncedData() async {
        mockTabManager = MockTabManager(recentlyAccessedNormalTabs: createTabs())
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient(type: "desktop"),
                                                       tabs: remoteTabs(idRange: 1...3))]

        let subject = createSubject()
        await loadNewData(for: subject)

        let recentTabs = await subject.getRecentTabData()
        XCTAssertEqual(recentTabs.count, 3)

        let syncTab = await subject.getSyncedTabData()
        XCTAssertNotNil(syncTab)
    }

    func testSyncTab_whenNoSyncTabsData_notReturned() async {
        let subject = createSubject()
        await loadNewData(for: subject)

        let syncTab = await subject.getSyncedTabData()
        XCTAssertNil(syncTab, "No sync tab since there's no remote tabs")
    }

    func testSyncTab_whenNoSyncAccount_notReturned() async {
        mockProfile.hasSyncableAccountMock = false
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient(type: "desktop"),
                                                       tabs: remoteTabs(idRange: 1...3))]
        let subject = createSubject()
        await loadNewData(for: subject)

        let syncTab = await subject.getSyncedTabData()
        XCTAssertNil(syncTab, "No sync tab since hasSyncableAccount is off")
    }

    func testSyncTab_noDesktopClients_notReturned() async {
        mockProfile.hasSyncableAccountMock = false
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient(), tabs: remoteTabs(idRange: 1...2))]
        let subject = createSubject()
        await loadNewData(for: subject)

        let syncTab = await subject.getSyncedTabData()
        XCTAssertNil(syncTab, "No sync tab since there's no desktop client")
    }

    func testSyncTab_oneDesktopClient_returned() async {
        let remoteClient = remoteClient(type: "desktop")
        let remoteTabs = remoteTabs(idRange: 1...3)
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs)]

        let subject = createSubject()
        await loadNewData(for: subject)

        let syncTab = await subject.getSyncedTabData()
        XCTAssertEqual(syncTab?.client.name, remoteClient.name)
        XCTAssertEqual(syncTab?.tab.title, remoteTabs.last?.title)
        XCTAssertEqual(syncTab?.tab.URL, remoteTabs.last?.URL)
    }

    func testSyncTab_multipleDesktopClients_returnsLast() async {
        let remoteClient = remoteClient(name: "Fake Client 2", type: "desktop")
        let remoteClientTabs = remoteTabs(idRange: 7...9)
        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs(idRange: 1...5)),
                                         ClientAndTabs(client: remoteClient, tabs: remoteClientTabs)]

        let subject = createSubject()
        await loadNewData(for: subject)

        let syncTab = await subject.getSyncedTabData()
        XCTAssertEqual(syncTab?.client.name, remoteClient.name)
        XCTAssertEqual(syncTab?.tab.title, remoteClientTabs.last?.title)
        XCTAssertEqual(syncTab?.tab.URL, remoteClientTabs.last?.URL)
    }

    // MARK: Helpers
    private func createSubject(file: StaticString = #file, line: UInt = #line) -> JumpBackInDataAdaptorImplementation {
        let dispatchQueue = MockDispatchQueue()
        let notificationCenter = MockNotificationCenter()

        let subject = JumpBackInDataAdaptorImplementation(
            profile: mockProfile,
            tabManager: mockTabManager,
            mainQueue: dispatchQueue,
            notificationCenter: notificationCenter
        )

        trackForMemoryLeaks(subject, file: file, line: line)
        trackForMemoryLeaks(dispatchQueue, file: file, line: line)

        return subject
    }

    private func loadNewData(for subject: JumpBackInDataAdaptorImplementation) async {
        let delegate = MockJumpBackInDelegate()
        await subject.setDelegate(delegate: delegate)
        let expectation = XCTestExpectation(description: "Wait for didLoadNewData to be called")
        delegate.didLoadNewDataHandler = {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 10.0)
    }

    private func createTab(profile: MockProfile, urlString: String? = "www.website.com") -> Tab {
        let tab = Tab(profile: profile, windowUUID: windowUUID)

        if let urlString = urlString {
            tab.url = URL(string: urlString)!
        }
        return tab
    }

    private func remoteClient(name: String = "Fake client", type: String? = nil) -> RemoteClient {
        return RemoteClient(guid: nil,
                            name: name,
                            modified: 1,
                            type: type,
                            formfactor: nil,
                            os: nil,
                            version: nil,
                            fxaDeviceId: nil)
    }

    private func remoteTabs(idRange: ClosedRange<Int> = 1...1) -> [RemoteTab] {
        var remoteTabs: [RemoteTab] = []

        for index in idRange {
            let tab = RemoteTab(clientGUID: String(index),
                                URL: URL(string: "www.mozilla.org")!,
                                title: "Mozilla \(index)",
                                history: [],
                                lastUsed: UInt64(index),
                                icon: nil,
                                inactive: false)
            remoteTabs.append(tab)
        }
        return remoteTabs
    }

    private func createTabs() -> [Tab] {
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        return [tab1, tab2, tab3]
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import XCTest
import WebKit
import Storage
import Shared

class JumpBackInViewModelTests: XCTestCase {
    var mockProfile: MockProfile!
    var mockTabManager: MockTabManager!

    var mockBrowserBarViewDelegate: MockBrowserBarViewDelegate!
    var stubBrowserViewController: BrowserViewController!

    var adaptor: JumpBackInDataAdaptorMock!

    override func setUp() {
        super.setUp()

        adaptor = JumpBackInDataAdaptorMock()
        mockProfile = MockProfile()
        mockTabManager = MockTabManager()
        stubBrowserViewController = BrowserViewController(
            profile: mockProfile,
            tabManager: TabManager(profile: mockProfile, imageStore: nil)
        )
        mockBrowserBarViewDelegate = MockBrowserBarViewDelegate()

        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
        adaptor = nil
        stubBrowserViewController = nil
        mockBrowserBarViewDelegate = nil
        mockTabManager = nil
        mockProfile = nil
    }

    // MARK: - Switch to group

    func test_switchToGroup_noBrowserDelegate_doNothing() {
        let sut = createSut(addDelegate: false)
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        var completionDidRun = false
        sut.onTapGroup = { tab in
            completionDidRun = true
        }

        sut.switchTo(group: group)

        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertFalse(completionDidRun)
    }

    func test_switchToGroup_noGroupedItems_doNothing() {
        let sut = createSut()
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        mockBrowserBarViewDelegate.inOverlayMode = true
        var completionDidRun = false
        sut.onTapGroup = { tab in
            completionDidRun = true
        }

        sut.switchTo(group: group)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 1)
        XCTAssertFalse(completionDidRun)
    }

    func test_switchToGroup_inOverlayMode_leavesOverlayMode() {
        let sut = createSut()
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        mockBrowserBarViewDelegate.inOverlayMode = true
        var completionDidRun = false
        sut.onTapGroup = { tab in
            completionDidRun = true
        }

        sut.switchTo(group: group)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 1)
        XCTAssertFalse(completionDidRun)
    }

    func test_switchToGroup_callCompletionOnFirstGroupedItem() {
        let sut = createSut()
        let expectedTab = createTab(profile: mockProfile)
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [expectedTab], timestamp: 0)
        mockBrowserBarViewDelegate.inOverlayMode = true
        var receivedTab: Tab?
        sut.onTapGroup = { tab in
            receivedTab = tab
        }

        sut.switchTo(group: group)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(expectedTab, receivedTab)
    }

    // MARK: - Switch to tab

    func test_switchToTab_noBrowserDelegate_doNothing() {
        let sut = createSut()
        let expectedTab = createTab(profile: mockProfile)
        sut.browserBarViewDelegate = nil

        sut.switchTo(tab: expectedTab)

        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertTrue(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_notInOverlayMode_switchTabs() {
        let sut = createSut()
        let tab = createTab(profile: mockProfile)
        mockBrowserBarViewDelegate.inOverlayMode = false

        sut.switchTo(tab: tab)

        XCTAssertFalse(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertFalse(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_inOverlayMode_leaveOverlayMode() {
        let sut = createSut()
        let tab = createTab(profile: mockProfile)
        mockBrowserBarViewDelegate.inOverlayMode = true

        sut.switchTo(tab: tab)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 1)
        XCTAssertFalse(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_tabManagerSelectsTab() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile)
        mockBrowserBarViewDelegate.inOverlayMode = true

        sut.switchTo(tab: tab1)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        guard !mockTabManager.lastSelectedTabs.isEmpty else {
            XCTFail("No tabs were selected in mock tab manager.")
            return
        }
        XCTAssertEqual(mockTabManager.lastSelectedTabs[0], tab1)
    }

    // MARK: - Jump back in layout

    func testMaxJumpBackInItemsToDisplay_compactJumpBackIn() {
        let sut = createSut()

        // iPhone layout
        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .compact
        trait.overridenVerticalSizeClass = .regular

        sut.updateSectionLayout(for: trait, isPortrait: true, device: .phone)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: false,
                                                                     device: .phone)
        XCTAssertEqual(jumpBackInItemsMax, 2)
        XCTAssertEqual(sut.sectionLayout, .compactJumpBackIn)
    }

    func testMaxJumpBackInItemsToDisplay_compactSyncedTab() {
        let sut = createSut()
        sut.featureFlags.set(feature: .jumpBackInSyncedTab, to: true)
        adaptor.syncedTab = JumpBackInSyncedTab(client: remoteClient, tab: remoteTab)

        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .compact
        trait.overridenVerticalSizeClass = .regular
        sut.refreshData(for: trait)
        sut.updateSectionLayout(for: trait, isPortrait: false, device: .pad)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: true,
                                                                     device: .pad)
        XCTAssertEqual(jumpBackInItemsMax, 0)
        XCTAssertEqual(sut.sectionLayout, .compactSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_compactJumpBackInAndSyncedTab() {
        let sut = createSut()
        sut.featureFlags.set(feature: .jumpBackInSyncedTab, to: true)
        adaptor.syncedTab = JumpBackInSyncedTab(client: remoteClient, tab: remoteTab)
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])

        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .compact
        trait.overridenVerticalSizeClass = .regular
        sut.refreshData(for: trait)
        sut.updateSectionLayout(for: trait, isPortrait: false, device: .pad)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: true,
                                                                     device: .pad)
        XCTAssertEqual(jumpBackInItemsMax, 1)
        XCTAssertEqual(sut.sectionLayout, .compactJumpBackInAndSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_regularIphone() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])
        adaptor.mockHasSyncedTabFeatureEnabled = false

        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular
        sut.refreshData(for: trait)
        sut.updateSectionLayout(for: trait, isPortrait: true, device: .phone)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: true,
                                                                     device: .phone)
        XCTAssertEqual(jumpBackInItemsMax, 4)
        XCTAssertEqual(sut.sectionLayout, .regular)
    }

    func testMaxJumpBackInItemsToDisplay_regularIpad() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])
        adaptor.mockHasSyncedTabFeatureEnabled = false

        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular
        sut.refreshData(for: trait)
        sut.updateSectionLayout(for: trait, isPortrait: true, device: .pad)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: true,
                                                                     device: .pad)
        XCTAssertEqual(jumpBackInItemsMax, 6)
        XCTAssertEqual(sut.sectionLayout, .regular)
    }

    func testMaxJumpBackInItemsToDisplay_regularWithSyncedTabIphone() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])
        adaptor.syncedTab = JumpBackInSyncedTab(client: remoteClient, tab: remoteTab)

        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular
        sut.refreshData(for: trait)
        sut.updateSectionLayout(for: trait, isPortrait: true, device: .phone)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: true,
                                                                     device: .phone)
        XCTAssertEqual(jumpBackInItemsMax, 2)
        XCTAssertEqual(sut.sectionLayout, .regularWithSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_regularWithSyncedTabIpad() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])
        adaptor.syncedTab = JumpBackInSyncedTab(client: remoteClient, tab: remoteTab)

        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular
        sut.refreshData(for: trait)
        sut.updateSectionLayout(for: trait, isPortrait: true, device: .pad)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: true,
                                                                     device: .pad)
        XCTAssertEqual(jumpBackInItemsMax, 4)
        XCTAssertEqual(sut.sectionLayout, .regularWithSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_regularWithSyncedTabIphone_hasNoSyncedTabFallsIntoRegularLayout() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])

        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular
        sut.refreshData(for: trait)
        sut.updateSectionLayout(for: trait, isPortrait: true, device: .phone)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: true,
                                                                     device: .phone)
        XCTAssertEqual(jumpBackInItemsMax, 4)
        XCTAssertEqual(sut.sectionLayout, .regular)
    }

    func testMaxJumpBackInItemsToDisplay_regularWithSyncedTabIpad_hasNoSyncedTabFallsIntoRegularLayout() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])

        let trait = MockTraitCollection()
        trait.overridenHorizontalSizeClass = .regular
        trait.overridenVerticalSizeClass = .regular
        sut.refreshData(for: trait)
        sut.updateSectionLayout(for: trait, isPortrait: true, device: .pad)
        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .jumpBackIn,
                                                                     hasAccount: true,
                                                                     device: .pad)
        XCTAssertEqual(jumpBackInItemsMax, 6)
        XCTAssertEqual(sut.sectionLayout, .regular)
    }

    // MARK: - Sync tab layout

    func testMaxDisplayedItemSyncedTab_withAccount() {
        let sut = createSut()

        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .syncedTab,
                                                                     hasAccount: true,
                                                                     device: .pad)
        XCTAssertEqual(jumpBackInItemsMax, 1)
    }

    func testMaxDisplayedItemSyncedTab_withoutAccount() {
        let sut = createSut()

        let jumpBackInItemsMax = sut.sectionLayout.maxItemsToDisplay(displayGroup: .syncedTab,
                                                                     hasAccount: false,
                                                                     device: .pad)
        XCTAssertEqual(jumpBackInItemsMax, 0)
    }

    // MARK: Refresh data

    func testRefreshData_noData() {
        let sut = createSut()
        sut.refreshData(for: MockTraitCollection())

        XCTAssertEqual(sut.jumpBackInList.tabs.count, 0)
        XCTAssertNil(sut.mostRecentSyncedTab)
    }

    func testRefreshData_jumpBackInList() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])
        sut.refreshData(for: MockTraitCollection())

        XCTAssertEqual(sut.jumpBackInList.tabs.count, 1)
        XCTAssertNil(sut.mostRecentSyncedTab)
    }

    func testRefreshData_syncedTab() {
        let sut = createSut()
        adaptor.syncedTab = JumpBackInSyncedTab(client: remoteClient, tab: remoteTab)
        sut.refreshData(for: MockTraitCollection())

        XCTAssertEqual(sut.jumpBackInList.tabs.count, 0)
        XCTAssertNotNil(sut.mostRecentSyncedTab)
    }

    // MARK: Did load new data

    func testDidLoadNewData_noNewData() {
        let sut = createSut()
        sut.didLoadNewData()

        XCTAssertEqual(sut.jumpBackInList.tabs.count, 0)
        XCTAssertNil(sut.mostRecentSyncedTab)
    }

    func testDidLoadNewData_jumpBackInList() {
        let sut = createSut()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        adaptor.jumpBackInList = JumpBackInList(group: nil, tabs: [tab1])
        sut.didLoadNewData()

        XCTAssertEqual(sut.jumpBackInList.tabs.count, 1)
        XCTAssertNil(sut.mostRecentSyncedTab)
    }

    func testDidLoadNewData_syncedTab() {
        let sut = createSut()
        adaptor.syncedTab = JumpBackInSyncedTab(client: remoteClient, tab: remoteTab)
        sut.didLoadNewData()

        XCTAssertEqual(sut.jumpBackInList.tabs.count, 0)
        XCTAssertNotNil(sut.mostRecentSyncedTab)
    }
}

// MARK: - Helpers
extension JumpBackInViewModelTests {

    func createSut(addDelegate: Bool = true) -> JumpBackInViewModel {
        let sut = JumpBackInViewModel(
            isZeroSearch: false,
            profile: mockProfile,
            isPrivate: false,
            tabManager: mockTabManager,
            adaptor: adaptor
        )
        if addDelegate {
            sut.browserBarViewDelegate = mockBrowserBarViewDelegate
        }

        trackForMemoryLeaks(sut)

        return sut
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

    var remoteTab: RemoteTab {
        return RemoteTab(clientGUID: "1",
                         URL: URL(string: "www.mozilla.org")!,
                         title: "Mozilla 1",
                         history: [],
                         lastUsed: 1,
                         icon: nil)
    }
}

class JumpBackInDataAdaptorMock: JumpBackInDataAdaptor {

    var mockHasSyncedTabFeatureEnabled: Bool = true
    var hasSyncedTabFeatureEnabled: Bool {
        return mockHasSyncedTabFeatureEnabled
    }

    var jumpBackInList = JumpBackInList(group: nil, tabs: [Tab]())
    func getJumpBackInData() -> JumpBackInList {
        return jumpBackInList
    }

    var syncedTab: JumpBackInSyncedTab?
    func getSyncedTabData() -> JumpBackInSyncedTab? {
        return syncedTab
    }

    func getHeroImage(forSite site: Site) -> UIImage? {
        return nil
    }

    func getFaviconImage(forSite site: Site) -> UIImage? {
        return nil
    }

    func refreshData(maxItemToDisplay: Int) {}
}

// MARK: - MockBrowserBarViewDelegate
class MockBrowserBarViewDelegate: BrowserBarViewDelegate {
    var inOverlayMode = false

    var leaveOverlayModeCount = 0

    func leaveOverlayMode(didCancel cancel: Bool) {
        leaveOverlayModeCount += 1
    }
}

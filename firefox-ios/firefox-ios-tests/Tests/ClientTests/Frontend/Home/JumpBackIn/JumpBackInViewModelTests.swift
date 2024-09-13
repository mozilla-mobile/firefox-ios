// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest
import WebKit
import Storage
import Shared
import Common

class JumpBackInViewModelTests: XCTestCase {
    var mockProfile: MockProfile!
    var mockTabManager: MockTabManager!

    var stubBrowserViewController: BrowserViewController!
    var adaptor: JumpBackInDataAdaptorMock!

    let windowUUID: WindowUUID = .XCTestDefaultUUID

    let iPhone14ScreenSize = CGSize(width: 390, height: 844)
    let sleepTime: UInt64 = 100_000_000
    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        adaptor = JumpBackInDataAdaptorMock()
        mockProfile = MockProfile()
        mockTabManager = MockTabManager()
        stubBrowserViewController = BrowserViewController(
            profile: mockProfile,
            tabManager: TabManagerImplementation(profile: mockProfile,
                                                 uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        )

        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
        adaptor = nil
        stubBrowserViewController = nil
        mockTabManager = nil
        mockProfile = nil
        AppContainer.shared.reset()
    }

    // MARK: - Switch to tab

    func test_switchToTab_notInOverlayMode_switchTabs() {
        let subject = createSubject()
        let tab = createTab(profile: mockProfile)

        subject.switchTo(tab: tab)

        XCTAssertFalse(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_inOverlayMode_leaveOverlayMode() {
        let subject = createSubject()
        let tab = createTab(profile: mockProfile)

        subject.switchTo(tab: tab)

        XCTAssertFalse(mockTabManager.lastSelectedTabs.isEmpty)
    }

    func test_switchToTab_tabManagerSelectsTab() {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile)

        subject.switchTo(tab: tab1)

        guard !mockTabManager.lastSelectedTabs.isEmpty else {
            XCTFail("No tabs were selected in mock tab manager.")
            return
        }
        XCTAssertEqual(mockTabManager.lastSelectedTabs[0], tab1)
    }

    // MARK: - Jump back in layout

    func testMaxJumpBackInItemsToDisplay_compactJumpBackIn() async {
        let subject = createSubject()

        // iPhone layout portrait
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: false,
                                                               device: .phone)
        XCTAssertEqual(maxItems.tabsCount, 2)
        XCTAssertEqual(maxItems.syncedTabCount, 0)
        XCTAssertEqual(subject.sectionLayout, .compactJumpBackIn)
    }

    func testMaxJumpBackInItemsToDisplay_compactSyncedTab() async {
        let subject = createSubject()
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))

        // iPhone layout portrait
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .phone)

        XCTAssertEqual(maxItems.tabsCount, 0)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .compactSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_compactJumpBackInAndSyncedTab() async {
        let subject = createSubject()
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])

        // iPhone layout portrait
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .phone)

        XCTAssertEqual(maxItems.tabsCount, 1)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .compactJumpBackInAndSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_mediumIphone() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        await adaptor.setMockHasSyncedTabFeatureEnabled(enabled: false)

        // iPhone layout landscape
        let trait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: false, device: .phone)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .phone)

        XCTAssertEqual(maxItems.tabsCount, 4)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .medium)
    }

    func testMaxJumpBackInItemsToDisplay_mediumWithSyncedTabIphone() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))

        // iPhone layout landscape
        let trait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: false, device: .phone)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .phone)

        XCTAssertEqual(maxItems.tabsCount, 2)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .mediumWithSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_mediumIpad() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        await adaptor.setMockHasSyncedTabFeatureEnabled(enabled: false)

        // iPad layout portrait
        let trait = MockTraitCollection().getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .pad)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .pad)

        XCTAssertEqual(maxItems.tabsCount, 4)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .medium)
    }

    func testMaxJumpBackInItemsToDisplay_mediumWithSyncedTabIpad() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))

        // iPad layout portrait
        let trait = MockTraitCollection().getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .pad)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .pad)

        XCTAssertEqual(maxItems.tabsCount, 2)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .mediumWithSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_regularIpad() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        await adaptor.setMockHasSyncedTabFeatureEnabled(enabled: false)

        // iPad layout landscape
        let trait = MockTraitCollection().getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: false, device: .pad)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .pad)

        XCTAssertEqual(maxItems.tabsCount, 6)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .regular)
    }

    // This case should never happen on a real device
    func testMaxJumpBackInItemsToDisplay_regularIphone() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        await adaptor.setMockHasSyncedTabFeatureEnabled(enabled: false)

        // iPhone layout portrait
        let trait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()
        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .phone)

        XCTAssertEqual(maxItems.tabsCount, 6)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .regular)
    }

    func testMaxJumpBackInItemsToDisplay_regularWithSyncedTabIpad() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))

        // iPad layout landscape
        let trait = MockTraitCollection().getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: false, device: .pad)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .pad)

        XCTAssertEqual(maxItems.tabsCount, 4)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .regularWithSyncedTab)
    }

    // This case should never happen on a real device
    func testMaxJumpBackInItemsToDisplay_regularWithSyncedTabIphone() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))

        // iPhone layout portrait
        let trait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .phone)

        XCTAssertEqual(maxItems.tabsCount, 4)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .regularWithSyncedTab)
    }

    func testMaxJumpBackInItemsToDisplay_mediumWithSyncedTabIphone_hasNoSyncedTabFallsIntoMediumLayout() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])

        // iPhone layout landscape
        let trait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: false, device: .phone)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .phone)

        XCTAssertEqual(maxItems.tabsCount, 4)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .medium)
    }

    func testMaxJumpBackInItemsToDisplay_regularWithSyncedTabIpad_hasNoSyncedTabFallsIntoRegularLayout() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])

        // iPad layout landscape
        let trait = MockTraitCollection().getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: false, device: .pad)
        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .pad)

        XCTAssertEqual(maxItems.tabsCount, 6)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
        XCTAssertEqual(subject.sectionLayout, .regular)
    }

    func testUpdateLayoutSectionBeforeRefreshData() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1, tab2, tab3])
        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)

        // Start in portrait
        let portraitTrait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        subject.refreshData(for: portraitTrait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)
        XCTAssertEqual(subject.sectionLayout, .compactJumpBackIn)

        // Mock rotation to landscape
        let landscapeTrait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()
        subject.refreshData(for: landscapeTrait, size: iPhone14ScreenSize, isPortrait: false, device: .phone)
        XCTAssertEqual(subject.sectionLayout, .medium)

        // Go back to portrait
        subject.refreshData(for: portraitTrait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)
        XCTAssertEqual(subject.sectionLayout, .compactJumpBackIn)
    }

    // MARK: - Sync tab layout

    func testMaxDisplayedItemSyncedTab_withAccount() {
        let subject = createSubject()

        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: true,
                                                               device: .pad)
        XCTAssertEqual(maxItems.tabsCount, 2)
        XCTAssertEqual(maxItems.syncedTabCount, 1)
    }

    func testMaxDisplayedItemSyncedTab_withoutAccount() {
        let subject = createSubject()

        let maxItems = subject.sectionLayout.maxItemsToDisplay(hasAccount: false,
                                                               device: .pad)
        XCTAssertEqual(maxItems.tabsCount, 2)
        XCTAssertEqual(maxItems.syncedTabCount, 0)
    }

    // MARK: Refresh data

    func testRefreshData_noData() async {
        let subject = createSubject()
        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: MockTraitCollection().getTraitCollection(), size: iPhone14ScreenSize)

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 0)
        XCTAssertNil(subject.mostRecentSyncedTab)
    }

    func testRefreshData_jumpBackInList() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: MockTraitCollection().getTraitCollection(), size: iPhone14ScreenSize)

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 1)
        XCTAssertNil(subject.mostRecentSyncedTab)
    }

    func testRefreshData_syncedTab() async {
        let subject = createSubject()
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: MockTraitCollection().getTraitCollection(), size: iPhone14ScreenSize)

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 0)
        XCTAssertNotNil(subject.mostRecentSyncedTab)
    }

    // MARK: - End to end

    func testCompactJumpBackIn_withThreeJumpBackInTabs() async {
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        await adaptor.setRecentTabs(recentTabs: [tab1, tab2, tab3])
        let subject = createSubject()

        // iPhone layout portrait
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)

        XCTAssertEqual(subject.sectionLayout, .compactJumpBackIn)
        let jumpBackIn = subject.jumpBackInList
        XCTAssertEqual(jumpBackIn.tabs.count, 2, "iPhone portrait has 2 tabs in it's jumpbackin layout")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
        XCTAssertEqual(jumpBackIn.tabs[1], tab2)
        XCTAssertFalse(jumpBackIn.tabs.contains(tab3), "The third tab doesn't appear")
    }

    func testCompactJumpBackIn_withOneJumpBackInTabs() async {
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        let subject = createSubject()

        // iPhone layout portrait
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)

        XCTAssertEqual(subject.sectionLayout, .compactJumpBackIn)
        let jumpBackIn = subject.jumpBackInList
        XCTAssertEqual(jumpBackIn.tabs.count, 1, "With a max of 2 items, only shows 1 item when only 1 is available")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
    }

    func testCompactJumpBackInAndSyncedTab_withThreeJumpBackInTabsAndARemoteTabs() async {
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        await adaptor.setRecentTabs(recentTabs: [tab1, tab2, tab3])
        let subject = createSubject()

        // iPhone layout portrait
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: true, device: .phone)

        let jumpBackIn = subject.jumpBackInList
        XCTAssertEqual(jumpBackIn.tabs.count, 1, "iPhone portrait has 1 tab in it's jumpbackin layout")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
        XCTAssertFalse(jumpBackIn.tabs.contains(tab2))
        XCTAssertFalse(jumpBackIn.tabs.contains(tab3))
        XCTAssertEqual(subject.sectionLayout, .compactJumpBackInAndSyncedTab)

        let syncTab = subject.mostRecentSyncedTab
        XCTAssertNotNil(syncTab, "iPhone portrait will show 1 sync tab")
    }

    func testMediumIphone_withThreeJumpbackInTabs() async {
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        await adaptor.setRecentTabs(recentTabs: [tab1, tab2, tab3])
        let subject = createSubject()

        // iPhone layout landscape
        let trait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: false, device: .phone)

        let jumpBackIn = subject.jumpBackInList
        XCTAssertEqual(jumpBackIn.tabs.count, 3, "iPhone landscape has 3 tabs in it's jumpbackin layout, up until 4")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
        XCTAssertEqual(jumpBackIn.tabs[1], tab2)
        XCTAssertEqual(jumpBackIn.tabs[2], tab3)
        XCTAssertEqual(subject.sectionLayout, .medium)

        let syncTab = subject.mostRecentSyncedTab
        XCTAssertNil(syncTab)
    }

    func testMediumWithSyncedTabIphone_withSyncTabAndJumpbackInTabs() async {
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
        await adaptor.setRecentTabs(recentTabs: [tab1, tab2, tab3])
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))
        let subject = createSubject()

        // iPhone layout landscape
        let trait = MockTraitCollection(verticalSizeClass: .compact).getTraitCollection()

        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)
        subject.refreshData(for: trait, size: iPhone14ScreenSize, isPortrait: false, device: .phone)

        let jumpBackIn = subject.jumpBackInList
        XCTAssertEqual(jumpBackIn.tabs.count, 2, "iPhone landscape has 2 tabs in it's jumpbackin layout, up until 2")
        XCTAssertEqual(jumpBackIn.tabs[0], tab1)
        XCTAssertEqual(jumpBackIn.tabs[1], tab2)
        XCTAssertFalse(jumpBackIn.tabs.contains(tab3))
        XCTAssertEqual(subject.sectionLayout, .mediumWithSyncedTab)

        let syncTab = subject.mostRecentSyncedTab
        XCTAssertNotNil(syncTab, "iPhone landscape will show 1 sync tab")
    }

    // MARK: Did load new data

    func testDidLoadNewData_noNewData() async {
        let subject = createSubject()
        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 0)
        XCTAssertNil(subject.recentSyncedTab)
    }

    func testDidLoadNewData_recentTabs() async {
        let subject = createSubject()
        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
        await adaptor.setRecentTabs(recentTabs: [tab1])
        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(subject.recentTabs.count, 1)
        XCTAssertNil(subject.recentSyncedTab)
    }

    func testDidLoadNewData_syncedTab() async {
        let subject = createSubject()
        await adaptor.setSyncedTab(syncedTab: JumpBackInSyncedTab(client: remoteClient, tab: remoteTab))
        subject.didLoadNewData()
        try? await Task.sleep(nanoseconds: sleepTime)

        XCTAssertEqual(subject.jumpBackInList.tabs.count, 0)
        XCTAssertNotNil(subject.recentSyncedTab)
    }
}

// MARK: - Helpers
extension JumpBackInViewModelTests {
    func createSubject() -> JumpBackInViewModel {
        let subject = JumpBackInViewModel(
            isZeroSearch: false,
            profile: mockProfile,
            isPrivate: false,
            theme: LightTheme(),
            tabManager: mockTabManager,
            adaptor: adaptor,
            wallpaperManager: WallpaperManager()
        )

        trackForMemoryLeaks(subject)

        return subject
    }

    func createTab(profile: MockProfile,
                   urlString: String? = "www.website.com") -> Tab {
        let tab = Tab(profile: profile, windowUUID: windowUUID)

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
                         icon: nil,
                         inactive: false)
    }
}

actor JumpBackInDataAdaptorMock: JumpBackInDataAdaptor {
    var recentTabs = [Tab]()
    func setRecentTabs(recentTabs: [Tab]) {
        self.recentTabs = recentTabs
    }

    func getRecentTabData() -> [Tab] {
        return recentTabs
    }

    var mockHasSyncedTabFeatureEnabled = true
    func setMockHasSyncedTabFeatureEnabled(enabled: Bool) {
        mockHasSyncedTabFeatureEnabled = enabled
    }

    func hasSyncedTabFeatureEnabled() -> Bool {
        return mockHasSyncedTabFeatureEnabled
    }

    var syncedTab: JumpBackInSyncedTab?
    func setSyncedTab(syncedTab: JumpBackInSyncedTab?) {
        self.syncedTab = syncedTab
    }

    func getSyncedTabData() -> JumpBackInSyncedTab? {
        return syncedTab
    }
}

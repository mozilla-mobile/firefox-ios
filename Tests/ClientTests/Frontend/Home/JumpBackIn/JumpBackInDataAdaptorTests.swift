// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest

// Laurie: rework test to adapt to adaptor
class JumpBackInDataAdaptorTests: XCTestCase {

    //    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_onIphoneLayout_noAccount_has2() {
    //        let sut = createSut()
    //        mockProfile.hasSyncableAccountMock = false
    //        sut.featureFlags.set(feature: .tabTrayGroups, to: false)
    //        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
    //        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
    //        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
    //        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateJumpBackInData(completion:) is called.")
    //
    //        // iPhone layout
    //        let trait = FakeTraitCollection()
    //        trait.overridenHorizontalSizeClass = .compact
    //        trait.overridenVerticalSizeClass = .regular
    //
    //        sut.updateData {
    //            sut.updateSectionLayout(for: trait, isPortrait: true, device: .phone) // get section layout calculated
    //            sut.refreshData(for: trait, device: .phone) // Refresh data for specific layout
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 5.0)
    //
    //        XCTAssertEqual(sut.jumpBackInList.tabs.count, 2, "iPhone portrait has 2 tabs in it's jumpbackin layout")
    //        XCTAssertEqual(sut.jumpBackInList.tabs[0], tab1)
    //        XCTAssertEqual(sut.jumpBackInList.tabs[1], tab2)
    //        XCTAssertFalse(sut.jumpBackInList.tabs.contains(tab3))
    //    }
    //
    //    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_onIphoneLayout_hasAccount_has1() {
    //        let sut = createSut()
    //        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(),
    //                                                       tabs: remoteTabs(idRange: 1...3))]
    //        sut.featureFlags.set(feature: .tabTrayGroups, to: false)
    //        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
    //        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
    //        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
    //        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateJumpBackInData(completion:) is called.")
    //
    //        // iPhone layout
    //        let trait = FakeTraitCollection()
    //        trait.overridenHorizontalSizeClass = .compact
    //        trait.overridenVerticalSizeClass = .regular
    //
    //        sut.updateData {
    //            sut.updateSectionLayout(for: trait, isPortrait: true, device: .phone) // get section layout calculated
    //            sut.refreshData(for: trait, device: .phone) // Refresh data for specific layout
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 10.0)
    //
    //        XCTAssertEqual(sut.jumpBackInList.tabs.count, 1, "iPhone portrait has 1 tab in it's jumpbackin layout")
    //        XCTAssertEqual(sut.jumpBackInList.tabs[0], tab1)
    //        XCTAssertFalse(sut.jumpBackInList.tabs.contains(tab2))
    //        XCTAssertFalse(sut.jumpBackInList.tabs.contains(tab3))
    //    }
    //
    //    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_oniPhoneLandscapeLayout_noAccount_has3() {
    //        let sut = createSut()
    //        mockProfile.hasSyncableAccountMock = false
    //        sut.featureFlags.set(feature: .tabTrayGroups, to: false)
    //        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
    //        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
    //        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
    //        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateJumpBackInData(completion:) is called.")
    //
    //        // iPhone landscape layout
    //        let trait = FakeTraitCollection()
    //        trait.overridenHorizontalSizeClass = .regular
    //        trait.overridenVerticalSizeClass = .regular
    //
    //        sut.updateData {
    //            sut.updateSectionLayout(for: trait, isPortrait: false, device: .phone) // get section layout calculated
    //            sut.refreshData(for: trait, device: .phone) // Refresh data for specific layout
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 1.0)
    //        guard sut.jumpBackInList.tabs.count > 0 else {
    //            XCTFail("Incorrect number of tabs in subject")
    //            return
    //        }
    //
    //        XCTAssertEqual(sut.jumpBackInList.tabs.count, 3, "iPhone landscape has 3 tabs in it's jumpbackin layout, up until 4")
    //        XCTAssertEqual(sut.jumpBackInList.tabs[0], tab1)
    //        XCTAssertEqual(sut.jumpBackInList.tabs[1], tab2)
    //        XCTAssertEqual(sut.jumpBackInList.tabs[2], tab3)
    //    }
    //
    //    func test_updateData_tabTrayGroupsDisabled_stubRecentTabsWithStartingURLs_oniPhoneLandscapeLayout_hasAccount_has2() {
    //        let sut = createSut()
    //        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(),
    //                                                       tabs: remoteTabs(idRange: 1...3))]
    //        sut.featureFlags.set(feature: .tabTrayGroups, to: false)
    //        let tab1 = createTab(profile: mockProfile, urlString: "www.firefox1.com")
    //        let tab2 = createTab(profile: mockProfile, urlString: "www.firefox2.com")
    //        let tab3 = createTab(profile: mockProfile, urlString: "www.firefox3.com")
    //        mockTabManager.nextRecentlyAccessedNormalTabs = [tab1, tab2, tab3]
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateJumpBackInData(completion:) is called.")
    //
    //        // iPhone landscape layout
    //        let trait = FakeTraitCollection()
    //        trait.overridenHorizontalSizeClass = .regular
    //        trait.overridenVerticalSizeClass = .regular
    //
    //        sut.updateData {
    //            sut.updateSectionLayout(for: trait, isPortrait: false, device: .phone) // get section layout calculated
    //            sut.refreshData(for: trait, device: .phone) // Refresh data for specific layout
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 5.0)
    //        guard sut.jumpBackInList.tabs.count > 0 else {
    //            XCTFail("Incorrect number of tabs in subject")
    //            return
    //        }
    //
    //        XCTAssertEqual(sut.jumpBackInList.tabs.count, 2, "iPhone landscape has 2 tabs in it's jumpbackin layout, up until 2")
    //        XCTAssertEqual(sut.jumpBackInList.tabs[0], tab1)
    //        XCTAssertEqual(sut.jumpBackInList.tabs[1], tab2)
    //        XCTAssertFalse(sut.jumpBackInList.tabs.contains(tab3))
    //    }
    //
    //    // MARK: Syncable Tabs
    //
    //    func test_updateData_mostRecentTab_noSyncableAccount() {
    //        let sut = createSut()
    //        mockProfile.hasSyncableAccountMock = false
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
    //        sut.updateData {
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 5.0)
    //        XCTAssertNil(sut.mostRecentSyncedTab, "There should be no most recent tab")
    //    }
    //
    //    func test_updateData_mostRecentTab_noCachedClients() {
    //        let sut = createSut()
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
    //        sut.updateData {
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 5.0)
    //        XCTAssertNil(sut.mostRecentSyncedTab, "There should be no most recent tab")
    //    }
    //
    //    func test_updateData_mostRecentTab_noDesktopClients() {
    //        let sut = createSut()
    //        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs(idRange: 1...2))]
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
    //        sut.updateData {
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 5.0)
    //        XCTAssertNil(sut.mostRecentSyncedTab, "There should be no most recent tab")
    //    }
    //
    //    func test_updateData_mostRecentTab_oneDesktopClient() {
    //        let sut = createSut()
    //        let remoteClient = remoteDesktopClient()
    //        let remoteTabs = remoteTabs(idRange: 1...3)
    //        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteClient, tabs: remoteTabs)]
    //
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
    //        sut.updateData {
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 5.0)
    //        XCTAssertEqual(sut.mostRecentSyncedTab?.client, remoteClient)
    //        XCTAssertEqual(sut.mostRecentSyncedTab?.tab, remoteTabs.last)
    //    }
    //
    //    func test_updateData_mostRecentTab_multipleDesktopClients() {
    //        let sut = createSut()
    //        let remoteClient = remoteDesktopClient(name: "Fake Client 2")
    //        let remoteClientTabs = remoteTabs(idRange: 7...9)
    //        mockProfile.mockClientAndTabs = [ClientAndTabs(client: remoteDesktopClient(), tabs: remoteTabs(idRange: 1...5)),
    //                                     ClientAndTabs(client: remoteClient, tabs: remoteClientTabs)]
    //
    //        let expectation = XCTestExpectation(description: "Main queue fires; updateRemoteTabs(completion:) is called.")
    //        sut.updateData {
    //            expectation.fulfill()
    //        }
    //
    //        wait(for: [expectation], timeout: 5.0)
    //        XCTAssertEqual(sut.mostRecentSyncedTab?.client, remoteClient)
    //        XCTAssertEqual(sut.mostRecentSyncedTab?.tab, remoteClientTabs.last)
    //    }
}

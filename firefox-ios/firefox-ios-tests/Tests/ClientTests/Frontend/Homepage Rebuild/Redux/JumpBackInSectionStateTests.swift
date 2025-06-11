// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage
import XCTest

@testable import Client

final class JumpBackInSectionStateTests: XCTestCase {
    var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        mockProfile = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.jumpBackInTabs, [])
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = jumpBackInSectionReducer()

        let newState = reducer(
            initialState,
            TabManagerAction(
                recentTabs: [createTab(urlString: "www.mozilla.org")],
                windowUUID: .XCTestDefaultUUID,
                actionType: TabManagerMiddlewareActionType.fetchedRecentTabs
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.jumpBackInTabs.count, 1)
        XCTAssertEqual(newState.jumpBackInTabs.first?.titleText, "www.mozilla.org")
        XCTAssertEqual(newState.jumpBackInTabs.first?.descriptionText, "Www.Mozilla.Org")
        XCTAssertEqual(newState.jumpBackInTabs.first?.siteURL, "www.mozilla.org")
        XCTAssertEqual(newState.jumpBackInTabs.first?.accessibilityLabel, "www.mozilla.org, Www.Mozilla.Org")
    }

    func test_fetchMostRecentSyncedTabAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = jumpBackInSectionReducer()

        let newState = reducer(
            initialState,
            RemoteTabsAction(
                mostRecentSyncedTab: RemoteTabConfiguration(client: remoteClient, tab: remoteTab),
                windowUUID: .XCTestDefaultUUID,
                actionType: RemoteTabsMiddlewareActionType.fetchedMostRecentSyncedTab
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.mostRecentSyncedTab?.titleText, "Mozilla")
        XCTAssertEqual(newState.mostRecentSyncedTab?.descriptionText, "Fake client")
        XCTAssertEqual(newState.mostRecentSyncedTab?.url.absoluteString, "www.mozilla.org")
        XCTAssertEqual(newState.mostRecentSyncedTab?.accessibilityLabel, "Tab pickup: Mozilla, Fake client")
    }

    func test_toggleShowSectionSetting_withToggleOn_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = jumpBackInSectionReducer()

        let newState = reducer(
            initialState,
            JumpBackInAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: JumpBackInActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldShowSection)
    }

    func test_toggleShowSectionSetting_withToggleOff_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = jumpBackInSectionReducer()

        let newState = reducer(
            initialState,
            JumpBackInAction(
                isEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: JumpBackInActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.shouldShowSection)
    }

    func test_sectionFlagEnabled_withoutUserPref_returnsExpectedState() {
           setupNimbusHNTJumpBackInSectionTesting(isEnabled: true)

           let initialState = createSubject()
           XCTAssertTrue(initialState.shouldShowSection)
       }

       func test_sectionFlagDisabled_withoutUserPref_returnsExpectedState() {
           setupNimbusHNTJumpBackInSectionTesting(isEnabled: false)

           let initialState = createSubject()
           XCTAssertFalse(initialState.shouldShowSection)
       }

       func test_sectionFlagEnabled_withUserPref_returnsExpectedState() {
           setupNimbusHNTJumpBackInSectionTesting(isEnabled: true)

           let initialState = createSubject()
           let reducer = jumpBackInSectionReducer()

           // Updates the jump back in section user pref
           let newState = reducer(
               initialState,
               JumpBackInAction(
                   isEnabled: false,
                   windowUUID: .XCTestDefaultUUID,
                   actionType: JumpBackInActionType.toggleShowSectionSetting
               )
           )
           XCTAssertFalse(newState.shouldShowSection)
       }

       func test_sectionFlagDisabled_withUserPref_returnsExpectedState() {
           setupNimbusHNTJumpBackInSectionTesting(isEnabled: false)

           let initialState = createSubject()
           let reducer = jumpBackInSectionReducer()

           // Updates the jump back in section user pref
           let newState = reducer(
               initialState,
               JumpBackInAction(
                   isEnabled: true,
                   windowUUID: .XCTestDefaultUUID,
                   actionType: JumpBackInActionType.toggleShowSectionSetting
               )
           )
           XCTAssertTrue(newState.shouldShowSection)
       }

    // MARK: - Private
    private func createSubject() -> JumpBackInSectionState {
        return JumpBackInSectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func jumpBackInSectionReducer() -> Reducer<JumpBackInSectionState> {
        return JumpBackInSectionState.reducer
    }

    func createTab(urlString: String) -> Tab {
        let tab = Tab(profile: mockProfile, windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: urlString)!
        return tab
    }

    private func setupNimbusHNTJumpBackInSectionTesting(isEnabled: Bool) {
        FxNimbus.shared.features.hntJumpBackInSectionFeature.with { _, _ in
            return HntJumpBackInSectionFeature(
                enabled: isEnabled
            )
        }
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
        return RemoteTab(clientGUID: String(1),
                         URL: URL(string: "www.mozilla.org")!,
                         title: "Mozilla",
                         history: [],
                         lastUsed: UInt64(1),
                         icon: nil,
                         inactive: false)
    }
}

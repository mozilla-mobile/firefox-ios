// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage
import Shared
import XCTest

import struct MozillaAppServices.Device

@testable import Client

final class RemoteTabPanelStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testTabsRefreshSkippedIfNotAllowed() {
        let initialState = RemoteTabsPanelState(windowUUID: .XCTestDefaultUUID)
        XCTAssertEqual(initialState.refreshState,
                       RemoteTabsPanelRefreshState.idle)

        let reducer = remoteTabsPanelReducer()

        let action = RemoteTabsPanelAction(windowUUID: WindowUUID.XCTestDefaultUUID,
                                           actionType: RemoteTabsPanelActionType.refreshTabs)
        let newState = reducer(initialState, action)

        // Refresh should fail since Profile.hasSyncableAccount
        // is false for unit test, expected state is .idle
        XCTAssertEqual(newState.refreshState,
                       RemoteTabsPanelRefreshState.idle)
    }

    func testTabsRefreshSuccessStateChange() {
        let initialState = createSubject()
        let reducer = remoteTabsPanelReducer()
        let testTabs = generateOneClientTwoTabs()
        let deviceId = "AAAAAA"
        let device = Device(id: deviceId,
                            displayName: "test device",
                            deviceType: .mobile,
                            capabilities: [.closeTabs, .sendTab],
                            pushSubscription: nil,
                            pushEndpointExpired: false,
                            isCurrentDevice: true,
                            lastAccessTime: nil)

        XCTAssertEqual(initialState.clientAndTabs.count, 0)

        let action = RemoteTabsPanelAction(clientAndTabs: testTabs,
                                           devices: [device],
                                           windowUUID: WindowUUID.XCTestDefaultUUID,
                                           actionType: RemoteTabsPanelActionType.refreshDidSucceed)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.clientAndTabs.count, 1)
        XCTAssertEqual(newState.clientAndTabs.first!.tabs.count, 2)
        XCTAssertEqual(newState.devices.count, 1)
        XCTAssertEqual(newState.devices[0].id, deviceId)
    }

    func testTabsRefreshBeginStateChange() {
        let initialState = createSubject()
        let reducer = remoteTabsPanelReducer()

        let action = RemoteTabsPanelAction(windowUUID: WindowUUID.XCTestDefaultUUID,
                                           actionType: RemoteTabsPanelActionType.refreshDidBegin)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.refreshState, RemoteTabsPanelRefreshState.refreshing)
    }

    func testTabsRefreshFailedStateChange() {
        let initialState = createSubject()
        let reducer = remoteTabsPanelReducer()

        let action = RemoteTabsPanelAction(reason: .failedToSync,
                                           windowUUID: WindowUUID.XCTestDefaultUUID,
                                           actionType: RemoteTabsPanelActionType.refreshDidFail)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.refreshState, RemoteTabsPanelRefreshState.idle)
        XCTAssertNotNil(newState.showingEmptyState)
    }

    func testRemoteDevicesChanged() {
        let initialState = createSubject()
        let reducer = remoteTabsPanelReducer()
        let deviceId = "AAAAAA"
        let device = Device(id: deviceId,
                            displayName: "test device",
                            deviceType: .mobile,
                            capabilities: [.closeTabs, .sendTab],
                            pushSubscription: nil,
                            pushEndpointExpired: false,
                            isCurrentDevice: true,
                            lastAccessTime: nil)

        let action = RemoteTabsPanelAction(clientAndTabs: nil,
                                           devices: [device],
                                           windowUUID: WindowUUID.XCTestDefaultUUID,
                                           actionType: RemoteTabsPanelActionType.remoteDevicesChanged)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.devices.count, 1)
        XCTAssertEqual(newState.devices[0].id, deviceId)
    }

    // MARK: - Private

    private func remoteTabsPanelReducer() -> Reducer<RemoteTabsPanelState> {
        return RemoteTabsPanelState.reducer
    }

    private func generateEmptyState() -> RemoteTabsPanelState {
        return RemoteTabsPanelState(windowUUID: .XCTestDefaultUUID)
    }

    private func generateOneClientTwoTabs() -> [ClientAndTabs] {
        let tab1 = RemoteTab(clientGUID: "123",
                             URL: URL(string: "https://mozilla.com")!,
                             title: "Mozilla Homepage",
                             history: [],
                             lastUsed: 0,
                             icon: nil,
                             inactive: false)
        let tab2 = RemoteTab(clientGUID: "123",
                             URL: URL(string: "https://google.com")!,
                             title: "Google Homepage",
                             history: [],
                             lastUsed: 0,
                             icon: nil,
                             inactive: false)
        let fakeTabs: [RemoteTab] = [tab1, tab2]
        let client = RemoteClient(guid: "123",
                                  name: "Client",
                                  modified: 0,
                                  type: "Type (Test)",
                                  formfactor: "Test",
                                  os: "macOS",
                                  version: "v1.0",
                                  fxaDeviceId: "12345")
        let fakeData = [ClientAndTabs(client: client, tabs: fakeTabs)]
        return fakeData
    }

    private func createSubject() -> RemoteTabsPanelState {
        let subject = RemoteTabsPanelState(windowUUID: .XCTestDefaultUUID)
        return subject
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import Shared
import XCTest

@testable import Client

final class RemoteTabPanelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testTableView_emptyStateNoRows() {
        let remotePanel = createSubject(state: generateEmptyState())
        let tableView = remotePanel.tableViewController.tableView

        XCTAssertNotNil(tableView)
        XCTAssertEqual(tableView!.numberOfSections, 0)
    }

    func testTableView_oneClientTwoRows() {
        let remotePanel = createSubject(state: generateStateOneClientTwoTabs())
        let tableView = remotePanel.tableViewController.tableView

        XCTAssertNotNil(tableView)
        XCTAssertEqual(tableView!.numberOfSections, 1)
        XCTAssertEqual(tableView!.numberOfRows(inSection: 0), 2)
    }

    // MARK: - Private

    private func generateEmptyState() -> RemoteTabsPanelState {
        return RemoteTabsPanelState(windowUUID: .XCTestDefaultUUID)
    }

    private func generateStateOneClientTwoTabs() -> RemoteTabsPanelState {
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
        return RemoteTabsPanelState(windowUUID: .XCTestDefaultUUID,
                                    refreshState: .idle,
                                    allowsRefresh: true,
                                    clientAndTabs: fakeData,
                                    showingEmptyState: nil,
                                    devices: [])
    }

    private func createSubject(state: RemoteTabsPanelState,
                               file: StaticString = #file,
                               line: UInt = #line) -> RemoteTabsPanel {
        let subject = RemoteTabsPanel(windowUUID: .XCTestDefaultUUID)
        subject.newState(state: state)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

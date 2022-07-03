// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage

@testable import Client

class RemoteTabsPanelTests: XCTestCase {
    private var profile: MockProfile!

    private var remoteClient: RemoteClient {
        return RemoteClient(
            guid: nil,
            name: "Fake client",
            modified: 1,
            type: nil,
            formfactor: nil,
            os: nil,
            version: nil,
            fxaDeviceId: nil
        )
    }
    private var remoteTabs: [RemoteTab] {
        return [RemoteTab(
            clientGUID: nil,
            URL: URL(string: "www.mozilla.org")!,
            title: "Mozilla",
            history: [],
            lastUsed: 1,
            icon: nil
        )]
    }

    func getMockProfileWithAttributes(
        hasAccount: Bool = true,
        clientAndTabs: [ClientAndTabs] = []
    ) -> MockProfile {
        profile = MockProfile()
        profile.hasSyncableAccountMock = hasAccount
        profile.mockClientAndTabs = clientAndTabs

        return profile
    }

    func subject(
        file: StaticString = #file,
        line: UInt = #line
    ) -> RemoteTabsPanel {
        let remoteTabsPanel = RemoteTabsPanel()
        remoteTabsPanel.loadViewIfNeeded()

        trackForMemoryLeaks(remoteTabsPanel, file: file, line: line)

        return remoteTabsPanel
    }

    func panelRefreshWithExpectation(panel: RemoteTabsPanel, completion: @escaping () -> Void) {
        let expectation = expectation(description: "Tabs should be refreshed")
        panel.tableViewController.refreshTabs {
            completion()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

}

/// Test panel states based on a varying of clients, tabs, and login state.
extension RemoteTabsPanelTests {

    func testHasNoSyncAccount() throws {
        let panel = subject()

        let dataSource = try XCTUnwrap(panel.tableViewController.tableViewDelegate as? RemoteTabsPanelErrorDataSource)
        XCTAssertEqual(dataSource.error, .notLoggedIn)
    }

    func testHasNoClients() {
        let panel = subject()
        panel.tableViewController.profile = getMockProfileWithAttributes()

        panelRefreshWithExpectation(panel: panel) {
            guard let dataSource = panel.tableViewController.tableViewDelegate as? RemoteTabsPanelErrorDataSource else {
                XCTFail("Should have error data source")
                return
            }

            XCTAssertEqual(dataSource.error, .noClients)
        }
    }

    func testHasNoTabs() {
        let clientAndTabs = ClientAndTabs(client: remoteClient, tabs: [])

        let panel = subject()
        panel.tableViewController.profile = getMockProfileWithAttributes(clientAndTabs: [clientAndTabs])

        panelRefreshWithExpectation(panel: panel) {
            guard let dataSource = panel.tableViewController.tableViewDelegate as? RemoteTabsPanelErrorDataSource else {
                XCTFail("Should have error data source")
                return
            }

            XCTAssertEqual(dataSource.error, .noTabs)
        }
    }

    func testHasTabs() {
        let clientAndTabs = ClientAndTabs(client: remoteClient, tabs: remoteTabs)

        let panel = subject()
        panel.tableViewController.profile = getMockProfileWithAttributes(clientAndTabs: [clientAndTabs])

        panelRefreshWithExpectation(panel: panel) {
            guard let dataSource = panel.tableViewController.tableViewDelegate as? RemoteTabsPanelClientAndTabsDataSource else {
                XCTFail("Should have panel and tabs data source")
                return
            }

            XCTAssertEqual(dataSource.clientAndTabs.count, 1)
            XCTAssertEqual(dataSource.clientAndTabs[0].tabs.count, 1)
        }
    }

    // MARK: Collapsing of section

    func testSectionCanCollapseAndReopen() {
        let clientAndTabs = ClientAndTabs(client: remoteClient, tabs: remoteTabs)

        let panel = subject()
        panel.tableViewController.profile = getMockProfileWithAttributes(clientAndTabs: [clientAndTabs])

        panelRefreshWithExpectation(panel: panel) {
            guard let dataSource = panel.tableViewController.tableViewDelegate as? RemoteTabsPanelClientAndTabsDataSource else {
                XCTFail("Should have panel and tabs data source")
                return
            }

            XCTAssertEqual(dataSource.hiddenSections.count, 0, "Has no collapsible section at first")
            dataSource.collapsibleSectionDelegate?.hideTableViewSection(0)
            XCTAssertEqual(dataSource.hiddenSections.count, 1, "Has collapsed")
            dataSource.collapsibleSectionDelegate?.hideTableViewSection(0)
            XCTAssertEqual(dataSource.hiddenSections.count, 0, "Has been reopened")
        }
    }

}

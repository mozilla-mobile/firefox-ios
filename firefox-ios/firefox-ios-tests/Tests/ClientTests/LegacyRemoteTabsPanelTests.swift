// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import Shared
import Common
@testable import Client

class LegacyRemoteTabsPanelTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        AppContainer.shared.reset()
        super.tearDown()
    }

    // MARK: States of panel

    func testHasNoSyncAccount() throws {
        let panel = createPanel(hasAccount: false)

        let dataSource = try XCTUnwrap(panel.tableViewController.tableViewDelegate as? LegacyRemoteTabsErrorDataSource)
        XCTAssertEqual(dataSource.error, .notLoggedIn)
    }

    func testHasNoSync() throws {
        let panel = createPanel(hasAccount: false, hasSyncEnabled: false)

        let dataSource = try XCTUnwrap(panel.tableViewController.tableViewDelegate as? LegacyRemoteTabsErrorDataSource)
        XCTAssertEqual(dataSource.error, .syncDisabledByUser)
    }

    func testHasNoClients() {
        let panel = createPanel()

        panelRefreshWithExpectation(panel: panel) {
            guard let dataSource = panel.tableViewController.tableViewDelegate as? LegacyRemoteTabsErrorDataSource
            else {
                XCTFail("Should have error data source")
                return
            }

            XCTAssertEqual(dataSource.error, .noClients)
        }
    }

    func testHasNoTabs() {
        let clientAndTabs = ClientAndTabs(client: remoteClient,
                                          tabs: [])
        let panel = createPanel(clientAndTabs: [clientAndTabs])

        panelRefreshWithExpectation(panel: panel) {
            guard let dataSource = panel.tableViewController.tableViewDelegate as? LegacyRemoteTabsErrorDataSource
            else {
                XCTFail("Should have error data source")
                return
            }

            XCTAssertEqual(dataSource.error, .noTabs)
        }
    }

    func testHasTabs() {
        let clientAndTabs = ClientAndTabs(client: remoteClient,
                                          tabs: remoteTabs)
        let panel = createPanel(clientAndTabs: [clientAndTabs])

        panelRefreshWithExpectation(panel: panel) {
            guard let dataSource = panel.tableViewController.tableViewDelegate as? RemoteTabsClientAndTabsDataSource
            else {
                XCTFail("Should have panel and tabs data source")
                return
            }

            XCTAssertEqual(dataSource.clientAndTabs.count, 1)
            XCTAssertEqual(dataSource.clientAndTabs[0].tabs.count, 1)
        }
    }

    // MARK: Collapsing of section

    func testSectionCanCollapseAndReopen() {
        let clientAndTabs = ClientAndTabs(client: remoteClient,
                                          tabs: remoteTabs)

        let panel = createPanel(clientAndTabs: [clientAndTabs])

        panelRefreshWithExpectation(panel: panel) {
            guard let dataSource = panel.tableViewController.tableViewDelegate as? RemoteTabsClientAndTabsDataSource
            else {
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

private extension LegacyRemoteTabsPanelTests {
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

    var remoteTabs: [RemoteTab] {
        return [RemoteTab(clientGUID: nil,
                          URL: URL(string: "www.mozilla.org")!,
                          title: "Mozilla",
                          history: [],
                          lastUsed: 1,
                          icon: nil,
                          inactive: false)]
    }

    func panelRefreshWithExpectation(panel: LegacyRemoteTabsPanel, completion: @escaping () -> Void) {
        let expectation = expectation(description: "Tabs should be refreshed")
        panel.tableViewController.refreshTabs {
            completion()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func createPanel(hasAccount: Bool = true,
                     hasSyncEnabled: Bool = true,
                     clientAndTabs: [ClientAndTabs] = [],
                     file: StaticString = #file,
                     line: UInt = #line) -> LegacyRemoteTabsPanel {
        let profile = MockProfile()
        profile.prefs.setBool(hasSyncEnabled, forKey: PrefsKeys.TabSyncEnabled)
        profile.hasSyncableAccountMock = hasAccount
        profile.mockClientAndTabs = clientAndTabs
        let panel = LegacyRemoteTabsPanel(profile: profile, windowUUID: windowUUID)
        panel.viewDidLoad()

        trackForMemoryLeaks(panel, file: file, line: line)

        return panel
    }
}

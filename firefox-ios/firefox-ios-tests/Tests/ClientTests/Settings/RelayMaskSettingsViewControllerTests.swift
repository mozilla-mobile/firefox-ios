// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

import XCTest

@testable import Client

@MainActor
final class RelayMaskSettingsViewControllerTests: XCTestCase {
    private var profile: Profile!
    private var tabManager: MockTabManager!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.profile = MockProfile()
        self.tabManager = MockTabManager()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        self.profile = nil
        self.tabManager = nil
        try await super.tearDown()
    }

    func testRelayMaskSettingsMemoryLeaks() throws {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    func testExpectedSettingsOutput() throws {
        let subject = createSubject()
        let result = subject.generateSettings()
        XCTAssertEqual(result.count, 2)

        let section1 = try XCTUnwrap(result[0])
        let section2 = try XCTUnwrap(result[1])
        XCTAssert(section1.children[0] is BoolSetting)
        XCTAssert(section2.children[0] is ManageRelayMasksSetting)
    }

    func testManageRelayMaskSettingURL() throws {
        let setting = try createSubjectAndReturnManageMasksSettingForTesting()
        XCTAssertEqual(setting.manageMasksURL, URL(string: "https://relay.firefox.com/accounts/profile"))
    }

    func testManageRelayMaskSettingsOptionOpensNewTab() throws {
        let setting = try createSubjectAndReturnManageMasksSettingForTesting()
        let tabCountStart = tabManager.addTabsURLs.count
        setting.onClick(nil)
        let tabCountFinish = tabManager.addTabsURLs.count
        XCTAssert(tabCountFinish == tabCountStart + 1)
    }

    // MARK: - Factory methods

    private func createSubject() -> RelayMaskSettingsViewController {
        let subject = RelayMaskSettingsViewController(profile: profile,
                                                      windowUUID: .XCTestDefaultUUID,
                                                      tabManager: tabManager)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func createSubjectAndReturnManageMasksSettingForTesting() throws -> ManageRelayMasksSetting {
        let subject = createSubject()
        let result = subject.generateSettings()

        let section2 = try XCTUnwrap(result[1])
        guard let setting = section2.children[0] as? ManageRelayMasksSetting else { XCTFail(); fatalError() }
        return setting
    }
}

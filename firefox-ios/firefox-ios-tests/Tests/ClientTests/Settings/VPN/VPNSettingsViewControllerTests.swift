// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class VPNSettingsViewControllerTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Init
    func test_init_setsTitle() {
        let subject = createSubject()
        XCTAssertEqual(subject.title, "Built-In VPN")
    }

    func test_init_usesGroupedStyle() {
        let subject = createSubject()
        XCTAssertEqual(subject.tableView.style, .grouped)
    }

    // MARK: - generateSettings
    func test_generateSettings_returnsNoSections() {
        let subject = createSubject()
        XCTAssertTrue(subject.generateSettings().isEmpty)
    }

    // MARK: - Helpers
    private func createSubject() -> VPNSettingsViewController {
        let subject = VPNSettingsViewController(windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}

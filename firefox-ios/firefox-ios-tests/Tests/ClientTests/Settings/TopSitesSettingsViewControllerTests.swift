// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TopSitesSettingsViewControllerTests: XCTestCase {
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        try await super.tearDown()
    }

    func testDoesNotLeak_whenGeneratedSettingsAreStored() {
        let subject = createSubject()
        // Mirrors viewWillAppear(_:), which retains the generated settings on the controller.
        subject.settings = subject.generateSettings()
    }

    func testGenerateSettings_withProfile_containsToggleAndRowSections() {
        let subject = createSubject()
        let sections = subject.generateSettings()

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections.first?.children.count, 2)
        XCTAssertTrue(sections.last?.children.first is TopSitesSettingsViewController.RowSettings)
    }

    // MARK: - Helpers
    private func createSubject() -> TopSitesSettingsViewController {
        let subject = TopSitesSettingsViewController(windowUUID: .XCTestDefaultUUID)
        subject.profile = profile
        trackForMemoryLeaks(subject)
        return subject
    }
}

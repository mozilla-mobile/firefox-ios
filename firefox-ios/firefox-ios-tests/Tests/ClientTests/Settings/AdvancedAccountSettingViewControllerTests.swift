// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class AdvancedAccountSettingViewControllerTests: XCTestCase {
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

    func testUseStageServerToggle_regeneratesSettings() throws {
        let subject = createSubject()
        subject.settings = subject.generateSettings()

        let useStage = try XCTUnwrap(subject.settings.first?.children.first as? BoolSetting)
        subject.settings = []
        useStage.settingDidChange?(true)

        XCTAssertFalse(subject.settings.isEmpty)
    }

    // MARK: - Helpers
    private func createSubject() -> AdvancedAccountSettingViewController {
        let subject = AdvancedAccountSettingViewController(style: .grouped,
                                                           windowUUID: .XCTestDefaultUUID)
        subject.profile = profile
        trackForMemoryLeaks(subject)
        return subject
    }
}

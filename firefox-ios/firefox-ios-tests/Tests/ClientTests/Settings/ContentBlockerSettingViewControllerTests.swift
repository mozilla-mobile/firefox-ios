// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class ContentBlockerSettingViewControllerTests: XCTestCase {
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

    func testStrengthSettings_reflectCurrentBlockingStrength() {
        let subject = createSubject()
        subject.settings = subject.generateSettings()

        let checkmarks = subject.settings.flatMap { $0.children }.compactMap { $0 as? CheckmarkSetting }

        XCTAssertFalse(checkmarks.isEmpty)
        // The default blocking strength (.basic) should be reflected by exactly one checked option
        XCTAssertEqual(checkmarks.filter { $0.isChecked() }.count, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> ContentBlockerSettingViewController {
        let subject = ContentBlockerSettingViewController(windowUUID: .XCTestDefaultUUID,
                                                          prefs: profile.prefs)
        subject.profile = profile
        trackForMemoryLeaks(subject)
        return subject
    }
}

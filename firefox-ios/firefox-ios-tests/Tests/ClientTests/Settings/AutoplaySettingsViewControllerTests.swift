// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class AutoplaySettingsViewControllerTests: XCTestCase {
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

    func testSelectingBlockAudio_updatesPreference() throws {
        let subject = createSubject()
        subject.settings = subject.generateSettings()

        let section = try XCTUnwrap(subject.settings.first)
        let blockAudio = try XCTUnwrap(section.children[1] as? CheckmarkSetting)
        blockAudio.onChecked()

        XCTAssertEqual(profile.prefs.stringForKey(AutoplayAccessors.autoplayPrefKey),
                       AutoplayAction.blockAudio.rawValue)
        XCTAssertTrue(blockAudio.isChecked())
    }

    // MARK: - Helpers

    private func createSubject() -> AutoplaySettingsViewController {
        let subject = AutoplaySettingsViewController(prefs: profile.prefs,
                                                     windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}

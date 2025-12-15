// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
class ReadingListPanelTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    override func setUp() async throws {
        try await super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        DependencyHelperMock().reset()
    }

    func testReaderPanelButtons() {
        let subject = createSubject()

        XCTAssertTrue(subject.bottomToolbarItems.isEmpty)
    }

    func testReaderPanel_ShouldDismissOnDone() {
        let subject = createSubject()

        XCTAssertTrue(subject.shouldDismissOnDone())
    }

    private func createSubject() -> ReadingListPanel {
        let profile = MockProfile()
        let subject = ReadingListPanel(profile: profile, windowUUID: windowUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}

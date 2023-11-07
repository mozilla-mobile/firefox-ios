// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class DownloadsPanelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testDownloadsPanelButtons() {
        let subject = createSubject()

        XCTAssertTrue(subject.bottomToolbarItems.isEmpty)
    }

    func testDownloadsPanel_ShouldDismissOnDone() {
        let subject = createSubject()

        XCTAssertTrue(subject.shouldDismissOnDone())
    }

    private func createSubject() -> DownloadsPanel {
        let subject = DownloadsPanel()
        trackForMemoryLeaks(subject)
        return subject
    }
}

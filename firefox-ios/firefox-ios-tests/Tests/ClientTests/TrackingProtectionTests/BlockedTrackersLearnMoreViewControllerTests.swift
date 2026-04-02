// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
final class BlockedTrackersLearnMoreViewControllerTests: XCTestCase {
    private var url: URL!

    override func setUp() async throws {
        try await super.setUp()
        AppContainer.shared.register(service: DefaultThemeManager(sharedContainerIdentifier: "") as ThemeManager)
    }

    override func tearDown() async throws {
        url = nil
        AppContainer.shared.reset()
        try await super.tearDown()
    }

    func testViewDidLoad_setsUpHierarchy() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertNotNil(subject.view)
        XCTAssertEqual(subject.children.count, 1)
    }

    func createSubject() -> BlockedTrackersLearnMoreViewController {
        let url = URL(string: "https://www.google.com")!
        self.url = url
        let blockedTrackersLearnMoreViewController = BlockedTrackersLearnMoreViewController(
            windowUUID: .XCTestDefaultUUID,
            url: url)
        trackForMemoryLeaks(blockedTrackersLearnMoreViewController)
        return blockedTrackersLearnMoreViewController
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import SwiftUI
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

    // MARK: - viewDidLoad
    func test_viewDidLoad_addsHostingControllerAsChild() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.children.count, 1)
        XCTAssertTrue(subject.children.first is UIHostingController<VPNSettingsViewContainer>)
    }

    // MARK: - Learn more
    func test_onLearnMoreTapped_pushesSettingsContentViewControllerWithLearnMoreURL() throws {
        let subject = createSubject()
        let navigationController = UINavigationController(rootViewController: subject)
        subject.loadViewIfNeeded()

        let hostingController = try XCTUnwrap(
            subject.children.first as? UIHostingController<VPNSettingsViewContainer>
        )
        hostingController.rootView.onLearnMoreTapped()

        let pushedController = try XCTUnwrap(navigationController.topViewController as? SettingsContentViewController)
        XCTAssertEqual(pushedController.url, VPNSettingsViewController.learnMoreURL)
    }

    // MARK: - Helpers
    private func createSubject() -> VPNSettingsViewController {
        let subject = VPNSettingsViewController(
            windowUUID: .XCTestDefaultUUID,
            prefs: MockProfilePrefs(),
            themeManager: MockThemeManager()
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

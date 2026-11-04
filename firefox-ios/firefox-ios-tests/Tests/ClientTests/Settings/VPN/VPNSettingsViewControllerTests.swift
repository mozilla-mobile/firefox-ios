// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import SwiftUI
import XCTest

@testable import Client

@available(iOS 17.0, *)
@MainActor
final class VPNSettingsViewControllerTests: XCTestCase {
    private var vpnManager: MockVPNRunnable!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        vpnManager = MockVPNRunnable()
    }

    override func tearDown() async throws {
        vpnManager = nil
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
    func test_learnMoreTapped_pushesSettingsContentViewControllerWithLearnMoreURL() throws {
        let subject = createSubject()
        let navigationController = UINavigationController(rootViewController: subject)

        subject.learnMoreTapped()

        let pushedController = try XCTUnwrap(navigationController.topViewController as? SettingsContentViewController)
        XCTAssertEqual(pushedController.url, VPNSettingsViewController.learnMoreURL)
    }

    // MARK: - Helpers
    private func createSubject() -> VPNSettingsViewController {
        let subject = VPNSettingsViewController(
            windowUUID: .XCTestDefaultUUID,
            themeManager: MockThemeManager(),
            viewModel: VPNSettingsViewModel(prefs: MockProfilePrefs(), vpnManager: vpnManager)
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

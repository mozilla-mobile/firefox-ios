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

    // MARK: - Locations
    func test_onLocationsTapped_pushesVPNLocationsViewController() throws {
        let subject = createSubject()
        let navigationController = UINavigationController(rootViewController: subject)
        subject.loadViewIfNeeded()

        let hostingController = try XCTUnwrap(
            subject.children.first as? UIHostingController<VPNSettingsViewContainer>
        )
        hostingController.rootView.onLocationsTapped()

        XCTAssertTrue(navigationController.topViewController is VPNLocationsViewController)
    }

    func test_onLocationSelected_savesSelection() throws {
        let prefs = MockProfilePrefs()
        let subject = createSubject(prefs: prefs)
        let navigationController = UINavigationController(rootViewController: subject)
        subject.loadViewIfNeeded()

        let hostingController = try XCTUnwrap(
            subject.children.first as? UIHostingController<VPNSettingsViewContainer>
        )
        hostingController.rootView.onLocationsTapped()
        let locationsController = try XCTUnwrap(navigationController.topViewController as? VPNLocationsViewController)
        locationsController.loadViewIfNeeded()
        let locationsHostingController = try XCTUnwrap(
            locationsController.children.first as? UIHostingController<VPNLocationsView>
        )
        locationsHostingController.rootView.onLocationSelected("DE")

        XCTAssertEqual(prefs.stringForKey(PrefsKeys.VPNSettings.selectedRegionCode), "DE")
    }

    // MARK: - Helpers
    private func createSubject(prefs: Prefs = MockProfilePrefs()) -> VPNSettingsViewController {
        let subject = VPNSettingsViewController(
            windowUUID: .XCTestDefaultUUID,
            prefs: prefs,
            themeManager: MockThemeManager()
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

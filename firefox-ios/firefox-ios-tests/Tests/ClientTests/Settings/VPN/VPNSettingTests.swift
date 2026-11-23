// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

@available(iOS 17.0, *)
@MainActor
final class VPNSettingTests: XCTestCase {
    private var delegate: MockSettingsFlowDelegate!
    private var settings: SettingsTableViewController!
    private var vpnManager: MockVPNManager!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        delegate = MockSettingsFlowDelegate()
        vpnManager = MockVPNManager()
        settings = SettingsTableViewController(
            style: .plain,
            windowUUID: .XCTestDefaultUUID,
            themeManager: MockThemeManager()
        )
    }

    override func tearDown() async throws {
        delegate = nil
        settings = nil
        vpnManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Init

    func test_init_setsAccessibilityIdentifier() {
        let subject = createSubject()
        XCTAssertEqual(subject.accessibilityIdentifier, AccessibilityIdentifiers.Settings.VPN.title)
    }

    func test_init_setsStyleToValue1() {
        let subject = createSubject()
        XCTAssertEqual(subject.style, .value1)
    }

    // MARK: - Status

    func test_status_whenVPNLimitReached_isPaused() {
        vpnManager.isLimitReached = true
        let subject = createSubject()
        XCTAssertEqual(subject.status?.string, .VPN.Settings.StatusPaused)
    }

    func test_status_whenVPNEnabledAndUnderLimit_isOn() {
        vpnManager.isRunning = true
        let subject = createSubject()
        XCTAssertEqual(subject.status?.string, .VPN.Settings.StatusOn)
    }

    func test_status_whenVPNOffAndUnderLimit_isOff() {
        vpnManager.isRunning = false
        let subject = createSubject()
        XCTAssertEqual(subject.status?.string, .VPN.Settings.StatusOff)
    }

    // MARK: - Accessory

    func test_accessoryView_isNilBeforeThemeIsSet() {
        let subject = createSubject()
        XCTAssertNil(subject.accessoryView)
    }

    func test_accessoryView_isDisclosureIndicatorAfterCellConfigured() {
        let subject = createSubject()
        subject.onConfigureCell(UITableViewCell(style: .value1, reuseIdentifier: nil), theme: LightTheme())
        XCTAssertNotNil(subject.accessoryView)
    }

    // MARK: - onClick

    func test_onClick_callsDelegateMethod() {
        let subject = createSubject()
        subject.onClick(nil)
        XCTAssertEqual(delegate.pressedVPNCalled, 1)
    }

    func test_onClick_withNavigationController() {
        let subject = createSubject()
        subject.onClick(UINavigationController())
        XCTAssertEqual(delegate.pressedVPNCalled, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> VPNSetting {
        let subject = VPNSetting(
            settings: settings,
            settingsDelegate: delegate,
            vpnManager: vpnManager
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

@MainActor
final class VPNSettingTests: XCTestCase {
    private var delegate: MockSettingsFlowDelegate!
    private var settings: SettingsTableViewController!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        delegate = MockSettingsFlowDelegate()
        settings = SettingsTableViewController(
            style: .plain,
            windowUUID: .XCTestDefaultUUID,
            themeManager: MockThemeManager()
        )
    }

    override func tearDown() async throws {
        delegate = nil
        settings = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Init

    func test_init_setsTitle() {
        let subject = createSubject()
        XCTAssertEqual(subject.title?.string, "Built-In VPN")
    }

    func test_init_setsAccessibilityIdentifier() {
        let subject = createSubject()
        XCTAssertEqual(subject.accessibilityIdentifier, AccessibilityIdentifiers.Settings.VPN.title)
    }

    func test_init_setsStyleToValue1() {
        let subject = createSubject()
        XCTAssertEqual(subject.style, .value1)
    }

    // MARK: - Status

    func test_status_showsNotConnected() {
        let subject = createSubject()
        XCTAssertEqual(subject.status?.string, "Not Connected")
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

    func test_onClick_callsDelegateMethodMultipleTimes() {
        let subject = createSubject()
        subject.onClick(nil)
        subject.onClick(nil)
        XCTAssertEqual(delegate.pressedVPNCalled, 2)
    }

    func test_onClick_withNavigationController() {
        let subject = createSubject()
        subject.onClick(UINavigationController())
        XCTAssertEqual(delegate.pressedVPNCalled, 1)
    }

    // MARK: - Title Attributes

    func test_title_hasCorrectTextColor() {
        let subject = createSubject()
        let titleAttributes = subject.title?.attributes(at: 0, effectiveRange: nil)
        let foregroundColor = titleAttributes?[.foregroundColor] as? UIColor
        XCTAssertNotNil(foregroundColor)
    }

    // MARK: - Helpers

    private func createSubject() -> VPNSetting {
        let subject = VPNSetting(
            settings: settings,
            settingsDelegate: delegate
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

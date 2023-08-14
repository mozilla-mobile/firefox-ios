// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import XCTest

@testable import Client

class ThemeSettingsControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testThemeSettingsUseSystemAppearance_WithoutRedux() {
        let subject = createSubject(usingRedux: false)
        let themeSwitch = createUseSystemThemeSwitch(isOn: true)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)

        XCTAssertTrue(subject.isSystemThemeOn)
        XCTAssertEqual(subject.tableView.numberOfSections, 1)
    }

    func testThemeSettingsUseCustomAppearance_WithoutRedux() {
        let subject = createSubject(usingRedux: false)
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)

        XCTAssertFalse(subject.isSystemThemeOn)
        XCTAssertEqual(subject.tableView.numberOfSections, 3)
    }

    func testUseManualTheme_WithoutRedux() {
        let subject = createSubject(usingRedux: false)
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)
        let tableView = UITableView()
        // Select Manual theme row
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 1))

        XCTAssertFalse(subject.isAutoBrightnessOn)
    }

    func testUpdateToLightManualTheme_WithoutRedux() {
        let subject = createSubject(usingRedux: false)
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)
        let tableView = UITableView()
        // Select to Manual theme row
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
        // Select Light theme
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 2))

        XCTAssertEqual(subject.themeManager.currentTheme.type, ThemeType.light)
    }

    func testUpdateToDarkManualTheme_WithoutRedux() {
        let subject = createSubject(usingRedux: false)
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)
        let tableView = UITableView()
        // Select to Manual theme row
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
        // Select Dark theme
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 1, section: 2))

        XCTAssertEqual(subject.themeManager.currentTheme.type, ThemeType.dark)
    }

    private func createSubject(usingRedux: Bool,
                               file: StaticString = #file,
                               line: UInt = #line) -> ThemeSettingsController {
        let subject = ThemeSettingsController()
        subject.isReduxIntegrationEnabled = usingRedux
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createUseSystemThemeSwitch(isOn: Bool) -> UISwitch {
        let themeSwitch = UISwitch(frame: .zero)
        themeSwitch.isOn = isOn
        return themeSwitch
    }
}

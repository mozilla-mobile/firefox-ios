// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import XCTest

@testable import Client

class ThemeSettingsControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testUseSystemAppearance_WithRedux() {
        let subject = createSubject()
        let themeSwitch = createUseSystemThemeSwitch(isOn: true)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)

        // Needed to wait for Redux action handled async in main thread
        let expectation = self.expectation(description: "Redux Middleware")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
            XCTAssertTrue(subject.isSystemThemeOn)
            XCTAssertEqual(subject.tableView.numberOfSections, 1)
        }
        waitForExpectations(timeout: 1)
    }

    func testUseCustomAppearance_WithRedux() {
        let subject = createSubject()
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)

        XCTAssertFalse(subject.isSystemThemeOn)
        XCTAssertEqual(subject.tableView.numberOfSections, 3)
    }

    func testUseManualTheme_WithRedux() {
        let subject = createSubject()
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)
        let tableView = UITableView()
        // Select Manual theme row
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 1))

        XCTAssertFalse(subject.isAutoBrightnessOn)
    }

    @MainActor
    func testUpdateToLightManualTheme_WithRedux() async throws {
        let subject = createSubject()
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)
        let tableView = UITableView()
        // Select to Manual theme row
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
        // Select Light theme
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 2))

        try await Task.sleep(nanoseconds: 100)

        XCTAssertEqual(subject.manualThemeType, ThemeType.light)
    }

    @MainActor
    func testUpdateToDarkManualTheme_WithRedux() async throws {
        let subject = createSubject()
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)
        let tableView = UITableView()
        // Select Dark theme
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 1, section: 2))

        try await Task.sleep(nanoseconds: 100)

        XCTAssertEqual(subject.manualThemeType, ThemeType.dark)
    }

    func testSystemBrightness_ForLightTheme_WithRedux() {
        let subject = createSubject()
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)
        let tableView = UITableView()
        // Select to Manual theme row
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 1, section: 1))

        // Set user threshold lower than systemBrightness
        let userBrightness = Float(UIScreen.main.brightness) - 0.2
        subject.themeManager.setAutomaticBrightnessValue(userBrightness)

        subject.systemBrightnessChanged()
        XCTAssertEqual(subject.themeManager.getCurrentTheme(for: windowUUID).type, .light)
    }

    func testSystemBrightnessChanged_ForDarkTheme_WithRedux() {
        let subject = createSubject()
        let themeSwitch = createUseSystemThemeSwitch(isOn: false)
        subject.systemThemeSwitchValueChanged(control: themeSwitch)
        let tableView = UITableView()
        // Select to Manual theme row
        subject.tableView(tableView, didSelectRowAt: IndexPath(row: 1, section: 1))

        // Set user threshold higher than systemBrightness
        let userBrightness = Float(UIScreen.main.brightness) + 0.2
        subject.themeManager.setAutomaticBrightnessValue(userBrightness)

        subject.systemBrightnessChanged()
        XCTAssertEqual(subject.themeManager.getCurrentTheme(for: windowUUID).type, .dark)
    }

    // MARK: - Private
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> ThemeSettingsController {
        let subject = ThemeSettingsController(windowUUID: .XCTestDefaultUUID)
        let action = ScreenAction(windowUUID: .XCTestDefaultUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .themeSettings)
        store.dispatch(action)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createUseSystemThemeSwitch(isOn: Bool) -> UISwitch {
        let themeSwitch = UISwitch(frame: .zero)
        themeSwitch.isOn = isOn
        return themeSwitch
    }
}

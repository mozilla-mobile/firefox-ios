// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

class A11ySettingsTests: BaseTestCase {
    func testSettingsMenuPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "When I open the Settings Screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Settings Screen") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsMainMenuAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "When I open the Settings Main Menu") { _ in
                navigator.nowAt(NewTabScreen)
                app.buttons["TabToolbar.menuButton"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }
        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "When I open the Settings Main Menu") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }
        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkButtonLabels(in: app,
                                            screenName: "Main Setting Page",
                                            missingLabels: &missingLabels
                )

                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Main Setting Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Main Setting Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsMainMenuExtendedAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "When I open the Extended Settings Main Menu") { _ in
                navigator.nowAt(NewTabScreen)
                app.buttons["TabToolbar.menuButton"].waitAndTap()
                app.scrollViews.element(boundBy: 0).swipeUp()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Main Setting Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )
                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Main Setting Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Main Setting Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsSyncAndSaveDataPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "When I open the Sync and Save Data Settings Screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Sync and Save Data"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Sync and Save Data Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsSyncAndSaveDataAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "When I open the Sync and Save Data Settings Main Menu") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)

                app.staticTexts["Sync and Save Data"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Sync and Save Data",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )
                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting - Sync and Save Data",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Sync and Save Data",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsBrowsingPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "When I open the Browsing Settings") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Browsing"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Browser Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "And I open the Mail App") { _ in
                app.staticTexts["Mail App"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Mail App Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "And I open the Allow Audio and Video App") { _ in
                app.buttons["Browsing"].waitAndTap()
                app.staticTexts["Allow Audio and Video"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsBrowsingAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "When I open the Browsing Settings") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)

                app.staticTexts["Browsing"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Browsing Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Browsing Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )

                A11yUtils.checkMissingLabels(
                    in: app.switches.allElementsBoundByIndex,
                    screenName: "Setting - Browsing Page",
                    missingLabels: &missingLabels,
                    elementType: "Switch"
                )
            }

        XCTContext
            .runActivity(named: "And I open the Mail App Settings") { _ in
                app.staticTexts["Mail App"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Browsing - Mail App Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Browsing - Mail App Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "And I open Allow Audio and Video Settings") { _ in
                // Navigate back
                app.buttons["Browsing"].waitAndTap()
                app.staticTexts["Allow Audio and Video"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Browsing - Allow Audio and Video Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting - Browsing - Allow Audio and Video Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Browsing - Allow Audio and Video Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsSearchPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }

        XCTContext
            .runActivity(named: "When I open the Search Settings") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Search"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "And I open the Default Search Engine Settings") { _ in
                app.tables.firstMatch.cells["Default Search Engine"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "And I open the Add Search Engine Settings") { _ in
                // Navigate back
                app.buttons["Cancel"].waitAndTap()
                app.staticTexts["Add Search Engine"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsSearchAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "When I open the Search Settings Menu") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)

                app.staticTexts["Search"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Search Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )
                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting - Search Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Search Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )

                A11yUtils.checkMissingLabels(
                    in: app.switches.allElementsBoundByIndex,
                    screenName: "Setting - Search Page",
                    missingLabels: &missingLabels,
                    elementType: "Switch"
                )
            }

        XCTContext
            .runActivity(named: "And I open the Default Search Engine Settings") { _ in
                app.tables.firstMatch.cells["Default Search Engine"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Search - Default Search Engine Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )
                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting - Search - Default Search Engine Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Search - Default Search Engine Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "And I open the Add Search Engine Settings") { _ in
                // Navigate back
                app.buttons["Cancel"].waitAndTap()
                app.staticTexts["Add Search Engine"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Search - Add Search Engine Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Search - Add Search Engine Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsNewTabPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "When I open the New Tab Settings") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["New Tab"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsNewTabAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "When I open the New Tab Settings Menu") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["New Tab"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkButtonLabels(
                    in: app,
                    screenName: "Setting - New Tab Page",
                    missingLabels: &missingLabels
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - New Tab Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsHomePagePageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "When I open the Homepage Settings") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Homepage"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                       try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "And I open the Top Sites Settings") { _ in
                app.tables.cells["TopSitesSettings"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                       try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "And I open the Top Sites Rows Settings") { _ in
                app.tables.firstMatch.cells["TopSitesRows"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                       try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsHomePageAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "When I open the Homepage Settings Menu") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Homepage"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Homepage Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.switches.allElementsBoundByIndex,
                    screenName: "Setting - Homepage Page",
                    missingLabels: &missingLabels,
                    elementType: "Switch"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Homepage Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "And I open the Top Site Settings Menu") { _ in
                app.tables.cells["TopSitesSettings"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Top Site Settings Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.switches.allElementsBoundByIndex,
                    screenName: "Setting - Top Site Settings Page",
                    missingLabels: &missingLabels,
                    elementType: "Switch"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Top Site Settings Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "And I open the Top Site Row Menu") { _ in
                app.tables.firstMatch.cells["TopSitesRows"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Rows Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Rows Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsThemePageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "When I open the Theme Settings") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Theme"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                       try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "When I open the Top Sites Settings Settings") { _ in
                app.tables.cells["TopSitesSettings"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                       try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "When I open the Top Sites Rows Settings") { _ in
                app.tables.firstMatch.cells["TopSitesRows"].tap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                       try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsThemeAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []

        XCTContext
            .runActivity(named: "When I open the Theme Settings Menu") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Theme"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Homepage Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting - Homepage Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Homepage Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "And I open the Top Sites Settings Menu") { _ in
                app.tables.cells["TopSitesSettings"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Top Site Settings Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )
                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting - Top Site Settings Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Top Site Settings Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "And I open the Top Sites Row Settings Menu") { _ in
                app.tables.firstMatch.cells["TopSitesRows"].tap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Rows Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting - Rows Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Rows Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsToolbarPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "When I open the Toolbar Settings") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Toolbar"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                       try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsToolbarAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "Given I open the Settings Screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }

        XCTContext
            .runActivity(named: "When I open the Toolbar Screen") { _ in
                app.staticTexts["Toolbar"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "And I check the accessibility Labels in the Toolbar Screen") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Toolbar Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Toolbar Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the Accessibility report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsAppIconPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "Given I open the setting screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }

        XCTContext
            .runActivity(named: "When I open the App Icon Settings") { _ in
                app.staticTexts["App Icon"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on App Icon Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsAppIconAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []

        XCTContext
            .runActivity(named: "Given I open the App Icon Settings Screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["App Icon"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - App Icon Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - App Icon Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )

                A11yUtils.checkMissingLabels(
                    in: app.images.allElementsBoundByIndex,
                    screenName: "Setting - App Icon Page",
                    missingLabels: &missingLabels,
                    elementType: "Image"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the Accessibility report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsSiriShortcutPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "When I open the Siri Shortcuts Settings") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Siri Shortcuts"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Allow Audio and Video Settings") { _ in
                do {
                       try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsSiriShortcutAccessibilityLabels() {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []

        XCTContext
            .runActivity(named: "When I open the Siri Shortcuts Settings Menu") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
                app.staticTexts["Siri Shortcuts"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "When I get the accessibility labels") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - App Icon Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - App Icon Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }

        XCTContext
            .runActivity(named: "Then I generate the report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    // Privacy Section
    func testSettingsAutofillsAndPasswordPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "Given I open the setting screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }
        XCTContext
            .runActivity(named: "When I open the Autofills & Passwords Settings") { _ in
                app.staticTexts["Autofills & Passwords"].waitAndTap()
            }
        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Autofills & Passwords Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsAutofillsAndPasswordAccessibilityReport() throws {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "Given I open the setting screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }
        XCTContext
            .runActivity(named: "When I open the Autofills & Passwords Settings") { _ in
                app.staticTexts["Autofills & Passwords"].waitAndTap()
            }
        XCTContext
            .runActivity(named: "And I check the accessibility Labels in the Autofills & Passwords Screen") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - App Icon Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - App Icon Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
            }
        XCTContext
            .runActivity(named: "Then I generate the Accessibility report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsDataManagementPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "Given I open the setting screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }
        XCTContext
            .runActivity(named: "When I open the Autofills & Passwords Settings") { _ in
                app.staticTexts["Data Management"].waitAndTap()
            }
        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Autofills & Passwords Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }

        XCTContext
            .runActivity(named: "And I open Website Data Settings in Data Management") { _ in
                app.staticTexts["Website Data"].waitAndTap()
            }

        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Website Data Settings in Data Management") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsTrackingProtectionPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "Given I open the setting screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }
        XCTContext
            .runActivity(named: "When I open the Tracking Protection Settings") { _ in
                app.staticTexts["Tracking Protection"].waitAndTap()
            }
        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Tracking Protection Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsTrackingProtectionAccessibilityReport() throws {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "Given I open the setting screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }
        XCTContext
            .runActivity(named: "When I open the Tracking Protection Settings") { _ in
                app.staticTexts["Tracking Protection"].waitAndTap()
            }
        XCTContext
            .runActivity(named: "And I check the accessibility Labels in the Tracking Protection Screen") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Tracking Protection Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Tracking Protection Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
                A11yUtils.checkMissingLabels(
                    in: app.switches.allElementsBoundByIndex,
                    screenName: "Setting - Tracking Protection Page",
                    missingLabels: &missingLabels,
                    elementType: "Switch"
                )
            }
        XCTContext
            .runActivity(named: "Then I generate the Accessibility report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }

    func testSettingsNotificationsPageAudit() throws {
        guard #available(iOS 17.0, *), !skipPlatform else { return }
        XCTContext
            .runActivity(named: "Given I open the setting screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }
        XCTContext
            .runActivity(named: "When I open the Notifications Settings") { _ in
                app.staticTexts["Notifications"].waitAndTap()
            }
        XCTContext
            .runActivity(named: "Then I perform the Accessibility Audit on Notification Settings") { _ in
                do {
                    try app.performAccessibilityAudit()
                } catch {
                    XCTFail("Accessibility audit failed with error: \(error)")
                }
            }
    }

    func testSettingsNotificationsAccessibilityReport() throws {
        var missingLabels: [A11yUtils.MissingAccessibilityElement] = []
        XCTContext
            .runActivity(named: "Given I open the setting screen") { _ in
                navigator.nowAt(NewTabScreen)
                navigator.goto(SettingsScreen)
            }
        XCTContext
            .runActivity(named: "When I open the Notification Settings") { _ in
                app.staticTexts["Notifications"].waitAndTap()
            }
        XCTContext
            .runActivity(named: "And I check the accessibility Labels in the Notifications Screen") { _ in
                A11yUtils.checkMissingLabels(
                    in: app.buttons.allElementsBoundByIndex,
                    screenName: "Setting - Tracking Protection Page",
                    missingLabels: &missingLabels,
                    elementType: "Button"
                )

                A11yUtils.checkMissingLabels(
                    in: app.staticTexts.allElementsBoundByIndex,
                    screenName: "Setting - Data Management Page",
                    missingLabels: &missingLabels,
                    elementType: "Static Text"
                )
                A11yUtils.checkMissingLabels(
                    in: app.switches.allElementsBoundByIndex,
                    screenName: "Setting - Data Management Page",
                    missingLabels: &missingLabels,
                    elementType: "Switch"
                )
            }
        XCTContext
            .runActivity(named: "Then I generate the Accessibility report") { _ in
                // Generate Report
                A11yUtils.generateAndAttachReport(missingLabels: missingLabels)
            }
    }
}

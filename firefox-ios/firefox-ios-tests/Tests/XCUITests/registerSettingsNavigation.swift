// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// swiftlint:disable all
import XCTest
import MappaMundi

func registerSettingsNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {

    let table = app.tables.element(boundBy: 0)

    map.addScreenState(SettingsScreen) { screenState in
        screenState.tap(table.cells["Sync"], to: SyncSettings, if: "fxaUsername != nil")
        screenState.tap(table.cells["SignInToSync"], to: Intro_FxASignin, if: "fxaUsername == nil")
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Search.searchNavigationBar], to: SearchSettings)
        screenState.tap(table.cells["NewTab"], to: NewTabSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Homepage.homeSettings], to: HomeSettings)
        screenState.tap(table.cells["Tabs"], to: TabsSettings)
        screenState.tap(table.cells["DisplayThemeOption"], to: DisplaySettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting], to: ToolbarSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Browsing.title], to: BrowsingSettings)
        screenState.tap(table.cells["SiriSettings"], to: SiriSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.AutofillsPasswords.title], to: AutofillPasswordSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.ClearData.title], to: ClearPrivateDataSettings)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.ContentBlocker.title],
            to: TrackingProtectionSettings
        )
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.ShowIntroduction.title],
                        to: ShowTourInSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Notifications.title],
                        to: NotificationsSettings)
        screenState.gesture(forAction: Action.ToggleNoImageMode) { userState in
            app.otherElements.tables.cells.switches[
                AccessibilityIdentifiers.Settings.BlockImages.title].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(AutofillPasswordSettings) { screenState in
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Logins.title], to: LoginsSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.CreditCards.title], to: CreditCardsSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Address.title], to: AddressesSettings)
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(SearchSettings) { screenState in
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.Search.customEngineViewButton],
            to: AddCustomSearchSettings
        )
        screenState.backAction = navigationControllerBackAction(for: app)
        screenState.gesture(forAction: Action.RemoveCustomSearchEngine) {userSTate in
            // Screengraph will go back to main Settings screen. Manually tap on settings
            app.navigationBars[AccessibilityIdentifiers.Settings.Search.searchNavigationBar].buttons["Edit"].waitAndTap()
            if #unavailable(iOS 17) {
                app.tables.buttons["Delete Mozilla Engine"].waitAndTap()
            } else {
                app.tables.buttons[AccessibilityIdentifiers.Settings.Search.deleteMozillaEngine].waitAndTap()
            }
            app.tables.buttons[AccessibilityIdentifiers.Settings.Search.deleteButton].waitAndTap()
        }
    }

    map.addScreenState(BrowsingSettings) { screenState in
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Browsing.autoPlay], to: AutoplaySettings)
        screenState.tap(table.cells["OpenWith.Setting"], to: MailAppSettings)

        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(LoginsSettings) {
        screenState in screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(CreditCardsSettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(AddressesSettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(AutoplaySettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(NotificationsSettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(SiriSettings) { screenState in
        screenState.gesture(forAction: Action.OpenSiriFromSettings) { userState in
            // Tap on Open New Tab to open Siri
            app.cells["SiriSettings"].staticTexts.element(boundBy: 0).waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(SyncSettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(DisplaySettings) { screenState in
        screenState.gesture(forAction: Action.SelectAutomatically) { userState in
            app.cells.staticTexts["Automatically"].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectManually) { userState in
            app.cells.staticTexts["Manually"].waitAndTap()
        }
        screenState.gesture(forAction: Action.SystemThemeSwitch) { userState in
            app.switches["SystemThemeSwitchValue"].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(ClearPrivateDataSettings) { screenState in
        screenState.tap(
            app.cells[AccessibilityIdentifiers.Settings.ClearData.websiteDataSection],
            to: WebsiteDataSettings
        )
        screenState.gesture(forAction: Action.AcceptClearPrivateData) { userState in
            app.tables.cells["ClearPrivateData"].waitAndTap()
            app.alerts.buttons["OK"].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(MailAppSettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(ShowTourInSettings) { screenState in
        screenState.gesture(to: Intro_FxASignin) {
            let turnOnSyncButton = app.buttons["signInOnboardingButton"]
            turnOnSyncButton.waitAndTap()
        }
    }

    map.addScreenState(TrackingProtectionSettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)

        screenState.tap(
            app.switches["prefkey.trackingprotection.normalbrowsing"],
            forAction: Action.SwitchETP
        ) { userState in
            userState.trackingProtectionSettingOnNormalMode = !userState.trackingProtectionSettingOnNormalMode
        }

        screenState.tap(
            app.cells["Settings.TrackingProtectionOption.BlockListStrict"],
            forAction: Action.EnableStrictMode
        ) { userState in
                userState.trackingProtectionPerTabEnabled = !userState.trackingProtectionPerTabEnabled
        }
    }

    map.addScreenState(AddCustomSearchSettings) { screenState in
        screenState.gesture(forAction: Action.AddCustomSearchEngine) { userState in
            app.tables.textViews["customEngineTitle"].staticTexts["Search Engine"].waitAndTap()
            app.typeText("Mozilla Engine")
            app.tables.textViews["customEngineUrl"].waitAndTap()

            let searchEngineUrl = "https://developer.mozilla.org/search?q=%s"
            let tablesQuery = app.tables
            let customengineurlTextView = tablesQuery.textViews["customEngineUrl"]
            sleep(1)
            UIPasteboard.general.string = searchEngineUrl
            customengineurlTextView.press(forDuration: 1.0)
            app.staticTexts["Paste"].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(TabsSettings) { screenState in
        screenState.tap(app.switches.element(boundBy: 0), forAction: Action.ToggleInactiveTabs)
        screenState.tap(app.switches.element(boundBy: 1), forAction: Action.ToggleTabGroups)
        screenState.tap(app.navigationBars.buttons["Settings"], to: SettingsScreen)
    }

    map.addScreenState(NewTabSettings) { screenState in
        screenState.gesture(forAction: Action.SelectNewTabAsBlankPage) { UserState in
            table.cells["NewTabAsBlankPage"].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectNewTabAsFirefoxHomePage) { UserState in
            table.cells["NewTabAsFirefoxHome"].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectNewTabAsCustomURL) { UserState in
            table.cells["NewTabAsCustomURL"].waitAndTap()
        }

        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(WebsiteDataSettings) { screenState in
        screenState.gesture(forAction: Action.AcceptClearAllWebsiteData) { userState in
            app.tables.cells["ClearAllWebsiteData"].staticTexts["Clear All Website Data"].waitAndTap()
            app.alerts.buttons["OK"].waitAndTap()
        }
        // The swipeDown() is a workaround for an intermittent issue that the search filed is not always in view.
        screenState.gesture(forAction: Action.TapOnFilterWebsites) { userState in
            app.searchFields["Filter Sites"].waitAndTap()
        }
        screenState.gesture(forAction: Action.ShowMoreWebsiteDataEntries) { userState in
            app.tables.cells["ShowMoreWebsiteData"].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(ToolbarSettings) { screenState in
        screenState.gesture(forAction: Action.SelectToolbarBottom) { UserState in
            app.cells[AccessibilityIdentifiers.Settings.SearchBar.bottomSetting].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectToolbarTop) { UserState in
            app.cells[AccessibilityIdentifiers.Settings.SearchBar.topSetting].waitAndTap()
        }

        screenState.backAction = navigationControllerBackAction(for: app)
    }
}

// swiftlint:enable all

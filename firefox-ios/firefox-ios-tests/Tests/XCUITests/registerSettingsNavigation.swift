// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

@MainActor // swiftlint:disable:next function_body_length
func registerSettingsNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    let table = app.tables.element(boundBy: 0)

    // swiftlint:disable:next closure_body_length
    map.addScreenState(SettingsScreen) { screenState in
        // `scrollIntoViewWithin: table` lets MappaMundi scroll a target row into view before tapping;
        // localized Settings rows are often pushed off-screen (still in the a11y tree but not hittable),
        // which would otherwise fail the tap.
        screenState.tap(table.cells["Sync"], to: SyncSettings, scrollIntoViewWithin: table, if: "fxaUsername != nil")
        screenState.tap(
            table.cells["SignInToSync"],
            to: Intro_FxASignin,
            scrollIntoViewWithin: table,
            if: "fxaUsername == nil")
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.Search.searchNavigationBar],
            to: SearchSettings,
            scrollIntoViewWithin: table)
        screenState.tap(table.cells["NewTab"], to: NewTabSettings, scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.Homepage.homeSettings],
            to: HomeSettings,
            scrollIntoViewWithin: table)
        screenState.tap(table.cells["DisplayThemeOption"], to: DisplaySettings, scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting],
            to: ToolbarSettings,
            scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.Browsing.title],
            to: BrowsingSettings,
            scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.Summarize.title],
            to: SummarizeSettings,
            scrollIntoViewWithin: table)
        screenState.tap(table.cells["SiriSettings"], to: SiriSettings, scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.AutofillsPasswords.title],
            to: AutofillPasswordSettings,
            scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.ClearData.title],
            to: ClearPrivateDataSettings,
            scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.ContentBlocker.title],
            to: TrackingProtectionSettings,
            scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.ShowIntroduction.title],
            to: ShowTourInSettings,
            scrollIntoViewWithin: table)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.Notifications.title],
            to: NotificationsSettings,
            scrollIntoViewWithin: table)
        screenState.gesture(forAction: Action.ToggleNoImageMode) { userState in
            app.otherElements.tables.cells.switches[
                AccessibilityIdentifiers.Settings.BlockImages.title].waitAndTap()
        }
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.AppIconSelection.settingsRowTitle],
            to: AppIconSettings,
            scrollIntoViewWithin: table)
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
            to: AddCustomSearchSettings,
            scrollIntoViewWithin: table
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
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.Browsing.autoPlay],
            to: AutoplaySettings,
            scrollIntoViewWithin: table)
        screenState.tap(table.cells["OpenWith.Setting"], to: MailAppSettings, scrollIntoViewWithin: table)

        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(SummarizeSettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    // swiftlint:disable closure_parameter_position
    map.addScreenState(LoginsSettings) {
        screenState in screenState.backAction = navigationControllerBackAction(for: app)
    }
    // swiftlint:enable closure_parameter_position

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
        screenState.gesture(forAction: Action.SelectAutomaticTheme) { userState in
            app.buttons[AccessibilityIdentifiers.Settings.Appearance.automaticThemeView].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectLightTheme) { userState in
            app.buttons[AccessibilityIdentifiers.Settings.Appearance.lightThemeView].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectDarkTheme) { userState in
            app.buttons[AccessibilityIdentifiers.Settings.Appearance.darkThemeView].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectBrowserDarkTheme) { userState in
            app.switches[AccessibilityIdentifiers.Settings.Appearance.darkModeToggle].waitAndTap()
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
            let pasteAction = app.staticTexts["Paste"]
            UIPasteboard.general.string = searchEngineUrl
            customengineurlTextView.mozWaitForElementToExist()
            customengineurlTextView.pressWithRetry(duration: 1.5, element: pasteAction)
            pasteAction.waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction(for: app)
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
            app.buttons[AccessibilityIdentifiers.Settings.SearchBar.bottomSetting].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectToolbarTop) { UserState in
            app.buttons[AccessibilityIdentifiers.Settings.SearchBar.topSetting].waitAndTap()
        }

        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(AppIconSettings) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

private let defaultURL = "https://www.mozilla.org/en-US/book/"

@MainActor
func registerUrlBarNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(URLBarLongPressMenu) { screenState in
        let menu = app.tables["Context Menu"].firstMatch

        if #unavailable(iOS 16) {
            screenState.gesture(forAction: Action.LoadURLByPasting, Action.LoadURL) { userState in
                UIPasteboard.general.string = userState.url ?? defaultURL
                menu.otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction].firstMatch.waitAndTap()
            }
        }

        screenState.gesture(forAction: Action.SetURLByPasting) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            menu.cells[AccessibilityIdentifiers.Photon.pasteAction].firstMatch.waitAndTap()
        }

        screenState.backAction = {
            if isTablet {
                // There is no Cancel option in iPad.
                app.otherElements["PopoverDismissRegion"].waitAndTap()
            } else {
                app.buttons["PhotonMenu.close"].waitAndTap()
            }
        }
        screenState.dismissOnUse = true
    }

    map.addScreenState(URLBarOpen) { screenState in
        // This is used for opening BrowserTab with default mozilla URL
        // For custom URL, should use Navigator.openNewURL or Navigator.openURL.
        screenState.gesture(forAction: Action.LoadURLByTyping) { userState in
            let url = userState.url ?? defaultURL
            let searchTextField = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
            // Workaround BB iOS13 be sure tap happens on url bar
            searchTextField.waitAndTap()
            searchTextField.waitAndTap()
            searchTextField.typeText(url)
            searchTextField.typeText("\r")
        }

        screenState.gesture(forAction: Action.SetURLByTyping, Action.SetURL) { userState in
            let url = userState.url ?? defaultURL
            let textsField = app.textFields.firstMatch
            // Workaround BB iOS13 be sure tap happens on url bar
            sleep(1)
            textsField.waitAndTap()
            textsField.waitAndTap()
            textsField.typeText("\(url)")
        }

        screenState.noop(to: HomePanelsScreen)
        screenState.noop(to: HomePanel_TopSites)

        screenState.backAction = {
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }
        screenState.dismissOnUse = true
    }
}

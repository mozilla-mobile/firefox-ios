// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerFxAccountNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(Intro_FxASignin) { screenState in
        screenState.tap(
            app.buttons["EmailSignIn.button"],
            forAction: Action.OpenEmailToSignIn,
            transitionTo: FxASigninScreen
        )
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.qrButton],
            forAction: Action.OpenEmailToQR,
            transitionTo: Intro_FxASignin
        )

        screenState.tap(app.navigationBars.buttons.element(boundBy: 0), to: SettingsScreen)
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(FxAccountManagementPage) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(FxCreateAccount) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)
    }

    map.addScreenState(FxASigninScreen) { screenState in
        screenState.backAction = navigationControllerBackAction(for: app)

        screenState.gesture(forAction: Action.FxATypeEmail) { userState in
            if #available(iOS 17, *) {
                app.webViews.textFields.firstMatch.tapAndTypeText(userState.fxaUsername!)
            } else {
                app.staticTexts[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField]
                    .waitAndTap()
                app.typeText(userState.fxaUsername!)
            }
        }
        screenState.gesture(forAction: Action.FxATypePasswordNewAccount) { userState in
            app.secureTextFields.element(boundBy: 1).tapAndTypeText(userState.fxaPassword!)
        }
        screenState.gesture(forAction: Action.FxATypePasswordExistingAccount) { userState in
            app.secureTextFields.element(boundBy: 0).tapAndTypeText(userState.fxaPassword!)
        }
        screenState.gesture(forAction: Action.FxATapOnContinueButton) { userState in
            app.webViews.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.continueButton].waitAndTap()
        }
        screenState.gesture(forAction: Action.FxATapOnSignInButton) { userState in
            app.webViews.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.signInButton].waitAndTap()
        }
        screenState.tap(app.webViews.links["Create an account"].firstMatch, to: FxCreateAccount)
    }
}

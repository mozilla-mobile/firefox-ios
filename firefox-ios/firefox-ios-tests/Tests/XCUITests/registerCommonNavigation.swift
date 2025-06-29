// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerCommonNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(WebPageLoading) { screenState in
        screenState.dismissOnUse = true

        // Would like to use app.otherElements.deviceStatusBars.networkLoadingIndicators.element
        // but this means exposing some of SnapshotHelper to another target.
        /*if !(app.progressIndicators.element(boundBy: 0).exists) {
            screenState.onEnterWaitFor(
                "exists != true",
                element: app.progressIndicators.element(boundBy: 0),
                if: "waitForLoading == true"
            )
        } else {
            screenState.onEnterWaitFor(
                element: app.progressIndicators.element(boundBy: 0),
                if: "waitForLoading == false"
            )
        }*/

        screenState.noop(to: BrowserTab, if: "waitForLoading == true")
        screenState.noop(to: BasicAuthDialog, if: "waitForLoading == false")
    }

    map.addScreenState(BasicAuthDialog) { screenState in
        screenState.onEnterWaitFor(element: app.alerts.element(boundBy: 0))
        screenState.backAction = {
            app.alerts.element(boundBy: 0).buttons.element(boundBy: 0).waitAndTap()
        }
        screenState.dismissOnUse = true
    }
}

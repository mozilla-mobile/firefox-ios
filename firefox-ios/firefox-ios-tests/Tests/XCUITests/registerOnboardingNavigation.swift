// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MappaMundi
import XCTest

func registerOnboardingNavigation(in map: MMScreenGraph<FxUserState>, app: XCUIApplication) {
    map.addScreenState(FirstRun) { screenState in
        screenState.noop(to: BrowserTab, if: "showIntro == false && showWhatsNew == true")
        screenState.noop(to: NewTabScreen, if: "showIntro == false && showWhatsNew == false")
        screenState.noop(to: allIntroPages[0], if: "showIntro == true")
    }

    // Add the intro screens.
    var i = 0
    let introLast = allIntroPages.count - 1
    for intro in allIntroPages {
        _ = i == 0 ? nil : allIntroPages[i - 1]
        let next = i == introLast ? nil : allIntroPages[i + 1]

        map.addScreenState(intro) { screenState in
            if let next = next {
                screenState.tap(app.buttons["nextOnboardingButton"], to: next)
            } else {
                let startBrowsingButton = app.buttons["startBrowsingOnboardingButton"]
                screenState.tap(startBrowsingButton, to: BrowserTab)
            }
        }

        i += 1
    }
}

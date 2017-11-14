/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nIntroSnapshotTests: L10nBaseSnapshotTests {
    override var skipIntro: Bool {
        return false
    }

    func testIntro() {
        let app = XCUIApplication()
        snapshot("Intro-1")
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        sleep(2)
        snapshot("Intro-2")
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        sleep(2)
        snapshot("Intro-3")
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        sleep(2)
        snapshot("Intro-4")
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        sleep(2)
        snapshot("01Intro-5")
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nIntroSnapshotTests: L10nBaseSnapshotTests {
    override var skipIntro: Bool {
        return false
    }

    func testIntro() {
        var num = 1
        navigator.visitNodes(allIntroPages) { screenName in
            snapshot("Intro-\(num)-\(screenName)")
            num += 1
        }
    }
}

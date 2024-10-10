// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

final class IntroScreenManagerTests: XCTestCase {
    var prefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() {
        prefs = nil
        super.tearDown()
    }

    func testHasntSeenIntroScreenYet_shouldShowIt() {
        let subject = IntroScreenManager(prefs: prefs)
        XCTAssertTrue(subject.shouldShowIntroScreen)
    }

    func testHasSeenIntroScreen_shouldNotShowIt() {
        let subject = IntroScreenManager(prefs: prefs)
        subject.didSeeIntroScreen()
        XCTAssertFalse(subject.shouldShowIntroScreen)
    }
}

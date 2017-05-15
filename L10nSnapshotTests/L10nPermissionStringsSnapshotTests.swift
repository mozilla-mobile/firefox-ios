/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nPermissionStringsSnapshotTests: L10nBaseSnapshotTests {
    func testNSLocationWhenInUseUsageDescription() {
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/geolocation.html", waitForOtherElementWithAriaLabel: "body")
        snapshot("15LocationDialog-01")
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/index.html", waitForOtherElementWithAriaLabel: "body")
    }
}

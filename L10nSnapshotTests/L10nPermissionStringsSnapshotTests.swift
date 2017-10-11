/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nPermissionStringsSnapshotTests: L10nBaseSnapshotTests {
    func testNSLocationWhenInUseUsageDescription() {
        var didShowDialog = false
        expectation(for: NSPredicate() {(_,_) in
            self.app.tap() // this is the magic tap that makes it work
            return didShowDialog
        }, evaluatedWith: NSNull(), handler: nil)

        addUIInterruptionMonitor(withDescription: "Location Dialog") { (alert) -> Bool in
            let okButton = alert.buttons["OK"]
            didShowDialog = true
            snapshot("15LocationDialog-01")
            if okButton.exists {
                okButton.tap()
                return true
            }
            return false
        }


        navigator.openURL("https://wopr.norad.org/~sarentz/fxios/testpages/geolocation.html")

        waitForExpectations(timeout: 10)

        snapshot("15LocationDialog-02")
    }
}

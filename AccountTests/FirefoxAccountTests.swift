/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Shared
import UIKit

import XCTest

class FirefoxAccountTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSerialization() {
        let d: [String: AnyObject] = [
            "version": 1,
            "configurationLabel": FirefoxAccountConfigurationLabel.Production.rawValue,
            "email": "testtest@test.com",
            "uid": "uid",
            "fxaDeviceId": "bogusid",
            "deviceRegistrationVersion": 0,
        ]

        let account1 = FirefoxAccount(
                configuration: FirefoxAccountConfigurationLabel.Production.toConfiguration(),
                email: d["email"] as! String,
                uid: d["uid"] as! String,
                fxaDeviceId: d["fxaDeviceId"] as! String,
                deviceRegistrationVersion: d["deviceRegistrationVersion"] as! Int,
                stateKeyLabel: Bytes.generateGUID(),
                state: SeparatedState())
        let d1 = account1.asDictionary()

        let account2 = FirefoxAccount.fromDictionary(d1)
        XCTAssertNotNil(account2)
        let d2 = account2!.asDictionary()

        for (k, v) in d {
            // Skip version, which is an Int.
            if let s = v as? String {
                XCTAssertEqual(s, d1[k] as? String, "Value for '\(k)' does not agree for manually created account.")
                XCTAssertEqual(s, d2[k] as? String, "Value for '\(k)' does not agree for deserialized account.")
            }
        }
    }
}

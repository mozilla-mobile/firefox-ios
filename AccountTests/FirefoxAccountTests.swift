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
        let ogPushSub = PushSubscription(channelID: "channel-id",
                                       endpoint: URL(string: "https://mozilla.com")!,
                                       p256dhPrivateKey: "private-key",
                                       p256dhPublicKey: "public-key",
                                       authKey: "auth-key")

        let d: [String: Any] = [
            "version": 1,
            "configurationLabel": FirefoxAccountConfigurationLabel.production.rawValue,
            "email": "testtest@test.com",
            "uid": "uid",
            "deviceRegistration": FxADeviceRegistration(id: "bogus-device", version: 0, lastRegistered: Date.now()),
            "pushRegistration": PushRegistration(uaid: "bogus-device-uaid", secret: "secret", subscription: ogPushSub),
        ]

        let account1 = FirefoxAccount(
                configuration: FirefoxAccountConfigurationLabel.production.toConfiguration(),
                email: d["email"] as! String,
                uid: d["uid"] as! String,
                deviceRegistration: (d["deviceRegistration"] as! FxADeviceRegistration),
                declinedEngines: nil,
                stateKeyLabel: Bytes.generateGUID(),
                state: SeparatedState())

        account1.pushRegistration = d["pushRegistration"] as? PushRegistration

        let d1 = account1.dictionary()

        let account2 = FirefoxAccount.fromDictionary(d1)
        XCTAssertNotNil(account2)
        let d2 = account2!.dictionary()

        for (k, v) in d {
            // Skip version, which is an Int.
            if let s = v as? String {
                XCTAssertEqual(s, d1[k] as? String, "Value for '\(k)' does not agree for manually created account.")
                XCTAssertEqual(s, d2[k] as? String, "Value for '\(k)' does not agree for deserialized account.")
            }
        }

        if let pubSub = account2?.pushRegistration?.defaultSubscription {
            XCTAssertEqual(pubSub, ogPushSub)
        } else {
            XCTFail("PushSubscription did not get decoded")
        }
    }
}

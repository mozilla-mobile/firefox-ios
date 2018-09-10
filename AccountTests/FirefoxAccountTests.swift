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

        let dictionary: [String: Any] = [
            "version": 1,
            "configurationLabel": FirefoxAccountConfigurationLabel.production.rawValue,
            "email": "testtest@test.com",
            "uid": "uid",
            "deviceRegistration": FxADeviceRegistration(id: "bogus-device", version: 0, lastRegistered: Date.now()),
            "pushRegistration": PushRegistration(uaid: "bogus-device-uaid", secret: "secret", subscription: ogPushSub),
        ]

        let account1 = FirefoxAccount(
                configuration: FirefoxAccountConfigurationLabel.production.toConfiguration(),
                email: dictionary["email"] as! String,
                uid: dictionary["uid"] as! String,
                deviceRegistration: (dictionary["deviceRegistration"] as! FxADeviceRegistration),
                declinedEngines: nil,
                stateKeyLabel: Bytes.generateGUID(),
                state: SeparatedState(),
                deviceName: "my iphone")

        account1.pushRegistration = dictionary["pushRegistration"] as? PushRegistration

        let dictionary1 = account1.dictionary()

        let account2 = FirefoxAccount.fromDictionary(dictionary1)
        XCTAssertNotNil(account2)
        let dictionary2 = account2!.dictionary()

        for (key, value) in dictionary {
            // Skip version, which is an Int.
            if let string = value as? String {
                XCTAssertEqual(string, dictionary1[key] as? String, "Value for '\(key)' does not agree for manually created account.")
                XCTAssertEqual(string, dictionary2[key] as? String, "Value for '\(key)' does not agree for deserialized account.")
            }
        }

        if let pubSub = account2?.pushRegistration?.defaultSubscription {
            XCTAssertEqual(pubSub, ogPushSub)
        } else {
            XCTFail("PushSubscription did not get decoded")
        }
    }
}

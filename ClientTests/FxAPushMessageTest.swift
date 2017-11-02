/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
@testable import Client
import Foundation
import FxA
import SwiftyJSON
import XCTest

class FxAPushMessageTest: XCTestCase {
    func testMessage_subscriptionDecryption() {
        var userInfo: [AnyHashable: Any] = [
            "chid": "034f52789f7b44ecaf119cc59231cdc1",
            "enc": "keyid=p256dh;salt=mYBHM3B_oXlEjV0HfgHZ1A",
            "body": "_tZf65gKC23STnTNuhtSSbrg1LScGiLjO4GOIuHlCGIFFEzcwsB-J-s3pe3qu2d24A-sKwVyolmShlMBEvEX_34f6FgXMs3k35g4u5STKgJMQxZ8VFDjtQqQfxfSIEt35pdKaPwXKH2zbs0xHC3qEJ0YMc60Eq8uAuQF7FQZ7ts",
            "cryptokey": "keyid=p256dh;dh=BNLZ2IWMNGioofzMBnSijySib0Pa-lwgBfLYIhqvvmKxprKgEh6JCDB2DBUmj9BuJCk6xJvBbPd-4x_8tb-qIPM;p256ecdsa=BP-OR33RzQSlrzD7_d1kYE9i9WjSIQAKTuhHxYNiPEF0i-wxeNIIwxthwU7zBTbumyxFUeydrmxcVKXugjBImRU",
            "con": "aesgcm",
            "ver": "gAAAAABY5hUl_Pi1bVI4ptqKzPWq_aulqXEO1eOx_ncUuwoz8zItWWLA4Ix1ZbDLTOkurqK1vE3N3y1ZXsp_MZ69QJYRuWg5V_3T_XUNVBxj8dnDcNAE-ep9_M5xeKiNdngdww-cqqMOxf-tI5ZoR2nQFqWSs51XGwMMIdsGNmUPqnR4w2Rzt6FYz-AsGCrHXJ3bmYbwpq4P",
            ]

        let subscription = PushSubscription(channelID: "channel",
                                            endpoint: URL(string: "https://example.ru")!,
                                            p256dhPrivateKey: "UDnicgor_Il7cLNTqSt--SrEblNBbgPA2yXAQ_b31xI",
                                            p256dhPublicKey: "BB4XdAhpVVU45NYSXHpRiubMYoaeb0A-y5aSGE437YKGHQihlvlZMv5D0ebK6WmFqzpIr217Kv9oCbZVDp1KGK4",
                                            authKey: "0gH7RiYYMhfHDQ1L1X4RMw")

        let body = userInfo["body"] as! String
        let enc = userInfo["enc"] as! String
        let cryptokey = userInfo["cryptokey"] as! String

        guard let plaintext = subscription.aesgcm(payload: body, encryptionHeader: enc, cryptoHeader: cryptokey) else {
            return XCTFail("Decryption failed")
        }

        let json = JSON(parseJSON: plaintext)

        XCTAssertEqual(json["command"].stringValue, "fxaccounts:device_connected")
    }

    func testMessageHandler() {
        let subscription = PushSubscription(channelID: "channel",
                                            endpoint: URL(string: "https://example.ru")!,
                                            p256dhPrivateKey: "t7dcZIN4w37UYjE6u3lBLB0WOShxqelkbJFKKzMDSsE",
                                            p256dhPublicKey: "BIXFDlhppL2lc5GcIXbGPa1iVdJn5ULYaF1ltJY9Qm17-tIC_9eEZXtalPpMRXsFmEKhdn2ttg3KQ3t-ztQ3ShQ",
                                            authKey: "a8E3EO5F6FFWdv4hAGyGyw")

        let userInfo: [AnyHashable: Any] = [
            AnyHashable("chid"): "f6defa012a6249e58bbfbf2995f8d425",
            AnyHashable("enc"): "keyid=p256dh;salt=nslkEsUqUg5sQ7_sRZfOjg",
            AnyHashable("body"): "Q1t-ttSwQMxUI64Ls3vOU-hE_qg1AIUzyLQSpEkx-8JITh5UJ7oq25faEc8XPoTYQoaHQ2d--QIK_yVorbt-0Yr7IO4BmtSSX-e4kSx76fWzqKjEpEt7Vr3Av5seEBeoAT2FZRzehkFjNVWoTw",
            AnyHashable("cryptokey"): "keyid=p256dh;dh=BNfUPK_8eUTZGOyXq07lthBfHeIxC2B7L_gF3cMGK1jVfDe9tlgxpHD_mbKrt3p12d7_O__wizhne2a1Eb7pZgk;p256ecdsa=BFSuld8S4PbRcgGe3OQPN9NyIOXx-ccUIMb0q6nIpH7Qf894wz0TIQTXQ7I7pWjZiN9KCdYVjNhyPtr1--37ois",
            AnyHashable("con"): "aesgcm",
            AnyHashable("ver"): "gAAAAABZLbG-m7EHhcMdrqs51SkESIZHsZjvw2QIu8LOeXxcKEy6wDVCprOKFAfJU44cinfJcDtCnO9EEyzpFt5e0HBDCLybGyThoZzmiod6zTLhTfAKZe-SyElSVCL0UDpJ_-U3UTUUHUaJXeRf0z6NvFM-uL39Jy-dwr3cuJoSDIcTPdChRPFiIS1hwokqMlxOn36azxOi",
            ]

        let profile = MockProfile()

        let account = FirefoxAccount(
            configuration: FirefoxAccountConfigurationLabel.production.toConfiguration(),
            email: "testtest@test.com",
            uid: "uid",
            deviceRegistration: nil,
            declinedEngines: nil,
            stateKeyLabel: "xxx",
            state: SeparatedState())

        let registration = PushRegistration(uaid: "uaid", secret: "secret", subscription: subscription)

        account.pushRegistration = registration
        profile.setAccount(account)

        let handler = FxAPushMessageHandler(with: profile)

        let expectation = XCTestExpectation()
        handler.handle(userInfo: userInfo).upon { maybe in
            XCTAssertTrue(maybe.isSuccess)
            XCTAssertEqual(maybe.successValue!, PushMessage.collectionChanged(collections: ["clients", "tabs"]))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func createHandler(_ profile: Profile = MockProfile()) -> FxAPushMessageHandler {
        let account = FirefoxAccount(
            configuration: FirefoxAccountConfigurationLabel.production.toConfiguration(),
            email: "testtest@test.com",
            uid: "uid",
            deviceRegistration: nil,
            declinedEngines: nil,
            stateKeyLabel: "xxx",
            state: SeparatedState())

        profile.setAccount(account)

        return FxAPushMessageHandler(with: profile)
    }

    func test_deviceConnected() {
        let handler = createHandler()

        let expectation = XCTestExpectation()
        handler.handle(plaintext: "{\"command\":\"fxaccounts:device_connected\",\"data\":{\"deviceName\": \"Use Nightly on Desktop\"}}").upon { maybe in
            XCTAssertTrue(maybe.isSuccess)
            guard let message = maybe.successValue else {
                return expectation.fulfill()
            }
            XCTAssertEqual(message, PushMessage.deviceConnected("Use Nightly on Desktop"))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func test_deviceDisconnected() {
        let profile = MockProfile()
        let handler = createHandler(profile)
        let prefs = profile.prefs

        let expectation = XCTestExpectation()
        handler.handle(plaintext: "{\"command\":\"fxaccounts:device_disconnected\",\"data\":{\"id\": \"not_this_device\"}}").upon { maybe in
            XCTAssertTrue(maybe.isSuccess)
            guard let message = maybe.successValue else {
                return expectation.fulfill()
            }
            XCTAssertEqual(message.messageType, .deviceDisconnected)
            XCTAssertFalse(prefs.boolForKey(PendingAccountDisconnectedKey) ?? false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)

    }

    func test_thisDeviceDisconnected() {
        let profile = MockProfile()
        let handler = createHandler(profile)

        let deviceRegistration = FxADeviceRegistration(id: "this-device-id", version: 1, lastRegistered: 0)
        profile.account?.deviceRegistration = deviceRegistration

        let prefs = profile.prefs

        let expectation = XCTestExpectation()
        handler.handle(plaintext: "{\"command\":\"fxaccounts:device_disconnected\",\"data\":{\"id\": \"\(deviceRegistration.id)\"}}").upon { maybe in
            guard let message = maybe.successValue else {
                return expectation.fulfill()
            }
            XCTAssertEqual(message, PushMessage.thisDeviceDisconnected)
            XCTAssertTrue(prefs.boolForKey(PendingAccountDisconnectedKey) ?? false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
        
    }
}

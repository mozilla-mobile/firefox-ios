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
                                            p256dhPrivateKey: "GwkCJrRPc0GNp4XHuPdLiUdGXYa6RzLtJBaF8N0Mvss",
                                            p256dhPublicKey: "BBOk-1UkZjLiTGbAw99JG17mdTTJuitgT7LX2wNS9ksh47gzSD-kCHeBnWF7EWi5XEHm2cxTydJL_3Co3v51Pb0",
                                            authKey: "kXRbfx0TqLHNgTU7qgeeZA")

        let userInfo: [AnyHashable: Any] = [
            AnyHashable("chid"): "5a700265e17d480fbf03090e688a0b5e",
            AnyHashable("enc"): "keyid=p256dh;salt=WWHbRTOP_A7RzJHquMBT2A",
            AnyHashable("body"): "0dKMh2RqlNCF6-8kdftvqiHpNzRVhiLAGXvVbTd96JuNScLoe8bqVjbeEMkTAQXSplq97ttR3CY4_ebBc_y1B30og7QOCO4e6SsHYjoZovxG6ELSnSAkD6x-08-EI4zZFb3EW7Zd",
            AnyHashable("cryptokey"): "keyid=p256dh;dh=BOGBP19K7Kf91iI-6BVChETCrG6A4i_mtlGeDL4HoKvtDbMD6lDC8ZKrkgRmVb5E5mi6YXXMGMqo6BV-NZTJwOU;p256ecdsa=BP-OR33RzQSlrzD7_d1kYE9i9WjSIQAKTuhHxYNiPEF0i-wxeNIIwxthwU7zBTbumyxFUeydrmxcVKXugjBImRU",
            AnyHashable("con"): "aesgcm",
            AnyHashable("ver"): "gAAAAABY57orjahDEtsVtTew7V2PSXxfqGRW9fsjJbPbQ-F6_eDPtgjlUGWwlmEVib0Nkw91k34IwJ6LSorwlenvgiM1ug07V92adN6hsLxLbYvtgnwk9ao7Ez6ldIzHhj1DCaBefcZnIfiFauvJvHrWaUXgiZRR22txyXs1UUBdcoqCtolmHox-hrHMw9qrkNfy67xIMKJ_"
        ]

        let profile = MockProfile()

        let account = FirefoxAccount(
            configuration: FirefoxAccountConfigurationLabel.production.toConfiguration(),
            email: "testtest@test.com",
            uid: "uid",
            deviceRegistration: nil,
            stateKeyLabel: "xxx",
            state: SeparatedState())

        let registration = PushRegistration(uaid: "uaid", secret: "secret", subscription: subscription)

        account.pushRegistration = registration
        profile.setAccount(account)

        let handler = FxAPushMessageHandler(with: profile)

        let expectation = XCTestExpectation()
        handler.handle(userInfo: userInfo).upon { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

}

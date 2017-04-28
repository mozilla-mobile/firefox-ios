/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA
import Shared
import SwiftyJSON

public class PushRegistration: NSObject, NSCoding {
    let uaid: String
    let secret: String
    // We don't need to have more than one subscription until WebPush is exposed to content Javascript
    // however, if/when we do, it'll make migrating easier if we have been serializing it like this all along.
    fileprivate var subscriptions: [String: PushSubscription]

    public var defaultSubscription: PushSubscription {
        return subscriptions[defaultSubscriptionID]!
    }

    public init(uaid: String, secret: String, subscriptions: [String: PushSubscription] = [:]) {
        self.uaid = uaid
        self.secret = secret

        self.subscriptions = subscriptions
    }

    public convenience init(uaid: String, secret: String, subscription: PushSubscription) {
        self.init(uaid: uaid, secret: secret, subscriptions: [defaultSubscriptionID: subscription])
    }

    @objc public convenience required init?(coder aDecoder: NSCoder) {
        guard let uaid = aDecoder.decodeObject(forKey: "uaid") as? String,
            let secret = aDecoder.decodeObject(forKey: "secret") as? String,
            let subscriptions = aDecoder.decodeObject(forKey: "subscriptions") as? [String: PushSubscription] else {
                fatalError("Cannot decode registration")
        }
        self.init(uaid: uaid, secret: secret, subscriptions: subscriptions)
    }

    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(uaid, forKey: "uaid")
        aCoder.encode(secret, forKey: "secret")
        aCoder.encode(subscriptions, forKey: "subscriptions")
    }

    public static func from(json: JSON) -> PushRegistration? {
        guard let endpointString = json["endpoint"].stringValue(),
              let endpoint = URL(string: endpointString),
              let secret = json["secret"].stringValue(),
              let uaid = json["uaid"].stringValue(),
              let channelID = json["channelID"].stringValue() else {
            return nil
        }
        guard let defaultSubscription = try? PushSubscription(channelID: channelID, endpoint: endpoint) else {
            return nil
        }
        return PushRegistration(uaid: uaid, secret: secret, subscriptions: [defaultSubscriptionID: defaultSubscription])
    }
}

fileprivate let defaultSubscriptionID = "defaultSubscription"
/// Small NSCodable class for persisting a channel subscription. 
/// We use NSCoder because we expect it to be stored in the profile.
public class PushSubscription: NSObject, NSCoding {
    let channelID: String
    let endpoint: URL

    let p256dhPublicKey: String
    let p256dhPrivateKey: String
    let authKey: String

    init(channelID: String, endpoint: URL, p256dhPrivateKey: String, p256dhPublicKey: String, authKey: String) {
        self.channelID =  channelID
        self.endpoint = endpoint
        self.p256dhPrivateKey = p256dhPrivateKey
        self.p256dhPublicKey = p256dhPublicKey
        self.authKey = authKey
    }

    convenience init(channelID: String, endpoint: URL, keys: PushKeys) {
        self.init(channelID: channelID,
                  endpoint: endpoint,
                  p256dhPrivateKey: keys.p256dhPrivateKey,
                  p256dhPublicKey: keys.p256dhPublicKey,
                  authKey: keys.auth)
    }

    convenience init(channelID: String, endpoint: URL) throws {
        let keys = try PushCrypto.sharedInstance.generateKeys()
        self.init(channelID: channelID, endpoint: endpoint, keys: keys)
    }

    @objc public convenience required init?(coder aDecoder: NSCoder) {
        guard let channelID = aDecoder.decodeObject(forKey: "channelID") as? String,
            let urlString = aDecoder.decodeObject(forKey: "endpoint") as? String,
            let endpoint = URL(string: urlString),
            let p256dhPrivateKey = aDecoder.decodeObject(forKey: "p256dhPrivateKey") as? String,
            let p256dhPublicKey = aDecoder.decodeObject(forKey: "p256dhPublicKey") as? String,
            let authKey = aDecoder.decodeObject(forKey: "authKey") as? String else {
            return nil
        }

        self.init(channelID: channelID,
                  endpoint: endpoint,
                  p256dhPrivateKey: p256dhPrivateKey,
                  p256dhPublicKey: p256dhPublicKey,
                  authKey: authKey)
    }

    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(channelID, forKey: "channelID")
        aCoder.encode(endpoint.absoluteString, forKey: "endpoint")
        aCoder.encode(p256dhPrivateKey, forKey: "p256dhPrivateKey")
        aCoder.encode(p256dhPublicKey, forKey: "p256dhPublicKey")
        aCoder.encode(authKey, forKey: "authKey")
    }
}

public extension PushSubscription {
    public func aesgcm(payload: String, encryptionHeader: String, cryptoHeader: String) -> String? {
        return try? PushCrypto.sharedInstance.aesgcm(ciphertext: payload, decryptWith: p256dhPrivateKey, authenticateWith: authKey, encryptionHeader: encryptionHeader, cryptoKeyHeader: cryptoHeader)
    }

    public func aes128gcm(payload: String) -> String? {
        return try? PushCrypto.sharedInstance.aes128gcm(payload: payload, decryptWith: p256dhPrivateKey, authenticateWith: authKey)
    }
}

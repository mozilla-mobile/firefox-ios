/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

public class PushRegistration: NSObject, NSCoding {
    let endpoint: NSURL
    let uaid: String
    let secret: String
    let channelID: String

    public init(uaid: String, secret: String, endpoint: NSURL, channelID: String) {
        self.uaid = uaid
        self.secret = secret
        self.endpoint = endpoint
        self.channelID = channelID
    }

    @objc public convenience required init?(coder aDecoder: NSCoder) {
        guard let uaid = aDecoder.decodeObject(forKey: "uaid") as? String,
            let secret = aDecoder.decodeObject(forKey: "secret") as? String,
            let urlString = aDecoder.decodeObject(forKey: "endpoint") as? String,
            let endpoint = NSURL(string: urlString),
            let channelID = aDecoder.decodeObject(forKey: "channelID") as? String else {
                fatalError("Cannot decode registration")
        }
        self.init(uaid: uaid, secret: secret, endpoint: endpoint, channelID: channelID)
    }

    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(uaid, forKey: "uaid")
        aCoder.encode(secret, forKey: "secret")
        aCoder.encode(endpoint.absoluteString, forKey: "endpoint")
        aCoder.encode(channelID, forKey: "channelID")
    }

    // TODO ???
    //     protected final @NonNull Map<String, PushSubscription> subscriptions;

    public static func from(json: JSON) -> PushRegistration? {
        guard let endpointString = json["endpoint"].rawString(),
              let endpoint = NSURL(string: endpointString),
              let secret = json["secret"].rawString(),
              let uaid = json["uaid"].rawString(),
              let channelID = json["channelID"].rawString() else {
            return nil
        }

        return PushRegistration(uaid: uaid, secret: secret, endpoint: endpoint, channelID: channelID)
    }

    func toJSON() -> JSON {
        var parameters = [String: String]()
        parameters["endpoint"] = endpoint.absoluteString!
        parameters["uaid"] = uaid
        parameters["secret"] = secret
        parameters["channelID"] = channelID

        return JSON(parameters)
    }
}

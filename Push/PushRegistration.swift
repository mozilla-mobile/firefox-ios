/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

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
        guard let uaid = aDecoder.decodeObjectForKey("uaid") as? String,
            let secret = aDecoder.decodeObjectForKey("secret") as? String,
            let urlString = aDecoder.decodeObjectForKey("endpoint") as? String,
            let endpoint = NSURL(string: urlString),
            let channelID = aDecoder.decodeObjectForKey("channelID") as? String else {
                fatalError("Cannot decode registration")
        }
        self.init(uaid: uaid, secret: secret, endpoint: endpoint, channelID: channelID)
    }

    @objc public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(uaid, forKey: "uaid")
        aCoder.encodeObject(secret, forKey: "secret")
        aCoder.encodeObject(endpoint.absoluteString, forKey: "endpoint")
        aCoder.encodeObject(channelID, forKey: "channelID")
    }

    // TODO ???
    //     protected final @NonNull Map<String, PushSubscription> subscriptions;

    public static func fromJSON(json: JSON) -> PushRegistration? {
        guard let endpointString = json["endpoint"].asString,
              let endpoint = NSURL(string: endpointString),
              let secret = json["secret"].asString,
              let uaid = json["uaid"].asString,
              let channelID = json["channelID"].asString else {
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

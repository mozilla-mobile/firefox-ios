/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public struct PushRegistration {
    let endpoint: NSURL
    let uaid: String
    let secret: String
    let channelID: String

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

        return PushRegistration(endpoint: endpoint, uaid: uaid, secret: secret, channelID: channelID)
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

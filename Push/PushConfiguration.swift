/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum PushConfigurationLabel: String {
    case Stage = "Stage"
    case Production = "Production"

    public func toConfiguration() -> PushConfiguration {
        switch self {
        case Stage: return StagePushConfiguration()
        case Production: return ProductionPushConfiguration()
        }
    }
}

public protocol PushConfiguration {
    init()

    var label: PushConfigurationLabel { get }

    /// The associated autopush server should speak the protocol documented at
    /// http://autopush.readthedocs.io/en/latest/http.html#push-service-http-api
    /// /v1/{type}/{app_id}
    /// type == apns
    /// app_id == the “platform” or “channel” of development (e.g. “firefox”, “beta”, “gecko”, etc.)
    var endpointURL: NSURL { get }
}


public struct StagePushConfiguration: PushConfiguration {
    public init() {}

    public let label = PushConfigurationLabel.Stage
    public let endpointURL = NSURL(string: "https://updates-autopush.stage.mozaws.net/v1/apns/0")!
}

public struct ProductionPushConfiguration: PushConfiguration {
    public init() {}

    public let label = PushConfigurationLabel.Production
    public let endpointURL = NSURL(string: "https://updates.push.services.mozilla.com/v1/apns/0")!
}

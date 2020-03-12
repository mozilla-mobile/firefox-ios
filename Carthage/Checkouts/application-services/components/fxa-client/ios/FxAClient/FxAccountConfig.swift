/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

open class FxAConfig {
    // FIXME: these should be lower case.
    // swiftlint:disable identifier_name
    public enum Server: String {
        case Release = "https://accounts.firefox.com"
        case Stable = "https://stable.dev.lcip.org"
        case Dev = "https://accounts.stage.mozaws.net"
        case China = "https://accounts.firefox.com.cn"
    }

    // swiftlint:enable identifier_name

    let contentUrl: String
    let clientId: String
    let redirectUri: String

    public init(contentUrl: String, clientId: String, redirectUri: String) {
        self.contentUrl = contentUrl
        self.clientId = clientId
        self.redirectUri = redirectUri
    }

    public init(withServer server: Server, clientId: String, redirectUri: String) {
        contentUrl = server.rawValue
        self.clientId = clientId
        self.redirectUri = redirectUri
    }

    public static func release(clientId: String, redirectUri: String) -> FxAConfig {
        return FxAConfig(withServer: FxAConfig.Server.Release, clientId: clientId, redirectUri: redirectUri)
    }

    public static func stable(clientId: String, redirectUri: String) -> FxAConfig {
        return FxAConfig(withServer: FxAConfig.Server.Stable, clientId: clientId, redirectUri: redirectUri)
    }

    public static func dev(clientId: String, redirectUri: String) -> FxAConfig {
        return FxAConfig(withServer: FxAConfig.Server.Dev, clientId: clientId, redirectUri: redirectUri)
    }

    public static func china(clientId: String, redirectUri: String) -> FxAConfig {
        return FxAConfig(withServer: FxAConfig.Server.China, clientId: clientId, redirectUri: redirectUri)
    }
}

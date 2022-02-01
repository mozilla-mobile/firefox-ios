/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

open class FxAConfig {
    public enum Server: String {
        case release = "https://accounts.firefox.com"
        case stable = "https://stable.dev.lcip.org"
        case stage = "https://accounts.stage.mozaws.net"
        case china = "https://accounts.firefox.com.cn"
        case localdev = "http://127.0.0.1:3030"
    }

    let contentUrl: String
    let clientId: String
    let redirectUri: String
    let tokenServerUrlOverride: String?

    public init(
        contentUrl: String,
        clientId: String,
        redirectUri: String,
        tokenServerUrlOverride: String? = nil
    ) {
        self.contentUrl = contentUrl
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.tokenServerUrlOverride = tokenServerUrlOverride
    }

    public init(
        server: Server,
        clientId: String,
        redirectUri: String,
        tokenServerUrlOverride: String? = nil
    ) {
        contentUrl = server.rawValue
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.tokenServerUrlOverride = tokenServerUrlOverride
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * In the URLs below, service=sync ensures that we always get the keys with signin messages,
 * and context=fx_desktop_v1 opts us in to the Desktop Sync postMessage interface.
 */
protocol FirefoxAccountConfiguration {
    var authEndpointURL: NSURL { get }
    var oauthEndpointURL: NSURL { get }
    var profileEndpointURL: NSURL { get }

    var signInURL: NSURL { get }
    var settingsURL: NSURL { get }
    var forceAuthURL: NSURL { get }
}

struct LatestDevFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    let authEndpointURL = NSURL(string: "https://latest.dev.lcip.org/auth")!
    let oauthEndpointURL = NSURL(string: "https://oauth-latest.dev.lcip.org")!
    let profileEndpointURL = NSURL(string: "https://latest.dev.lcip.org/profile")!

    let signInURL = NSURL(string: "https://latest.dev.lcip.org/signin?service=sync&context=fx_desktop_v1")!
    let settingsURL = NSURL(string: "https://latest.dev.lcip.org/settings?context=fx_desktop_v1")!
    let forceAuthURL = NSURL(string: "https://latest.dev.lcip.org/force_auth?service=sync&context=fx_desktop_v1")!
}

struct StableDevFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    let authEndpointURL = NSURL(string: "https://stable.dev.lcip.org/auth")!
    let oauthEndpointURL = NSURL(string: "https://oauth-stable.dev.lcip.org")!
    let profileEndpointURL = NSURL(string: "https://stable.dev.lcip.org/profile")!

    let signInURL = NSURL(string: "https://stable.dev.lcip.org/signin?service=sync&context=fx_desktop_v1")!
    let settingsURL = NSURL(string: "https://stable.dev.lcip.org/settings?context=fx_desktop_v1")!
    let forceAuthURL = NSURL(string: "https://stable.dev.lcip.org/force_auth?service=sync&context=fx_desktop_v1")!
}

struct ProductionFirefoxAccountConfiguration: FirefoxAccountConfiguration {
    let authEndpointURL = NSURL(string: "https://api.accounts.firefox.com/v1")!
    let oauthEndpointURL = NSURL(string: "https://oauth.accounts.firefox.com/v1")!
    let profileEndpointURL = NSURL(string: "https://profile.accounts.firefox.com/v1")!

    let signInURL = NSURL(string: "https://accounts.firefox.com/signin?service=sync&context=fx_desktop_v1")!
    let settingsURL = NSURL(string: "https://accounts.firefox.com/settings?context=fx_desktop_v1")!
    let forceAuthURL = NSURL(string: "https://accounts.firefox.com/force_auth?service=sync&context=fx_desktop_v1")!
}

protocol Sync15Configuration {
    var tokenServerEndpointURL: NSURL { get }
}

struct ProductionSync15Configuration: Sync15Configuration {
    let tokenServerEndpointURL = NSURL(string: "https://token.services.mozilla.com/1.0/sync/1.5")!
}

struct StageSync15Configuration: Sync15Configuration {
    let tokenServerEndpointURL = NSURL(string: "https://token.stage.mozaws.net/1.0/sync/1.5")!
}

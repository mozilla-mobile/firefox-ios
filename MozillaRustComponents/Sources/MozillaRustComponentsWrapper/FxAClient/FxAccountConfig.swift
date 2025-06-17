/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// Compatibility wrapper around the `FxaConfig` struct.  Let's keep this around for a bit to avoid
// too many breaking changes for the consumer, but at some point soon we should switch them to using
// the standard class
//
// Note: FxAConfig and FxAServer, with an upper-case "A" are the wrapper classes.  FxaConfig and
// FxaServer are the classes from Rust.
open class FxAConfig {
    public enum Server: String {
        case release
        case stable
        case stage
        case china
        case localdev
    }

    // FxaConfig with lowercase "a" is the version the Rust code uses
    let rustConfig: FxaConfig

    public init(
        contentUrl: String,
        clientId: String,
        redirectUri: String,
        tokenServerUrlOverride: String? = nil
    ) {
        rustConfig = FxaConfig(
            server: FxaServer.custom(url: contentUrl),
            clientId: clientId,
            redirectUri: redirectUri,
            tokenServerUrlOverride: tokenServerUrlOverride
        )
    }

    public init(
        server: Server,
        clientId: String,
        redirectUri: String,
        tokenServerUrlOverride: String? = nil
    ) {
        let rustServer: FxaServer
        switch server {
        case .release:
            rustServer = FxaServer.release
        case .stable:
            rustServer = FxaServer.stable
        case .stage:
            rustServer = FxaServer.stage
        case .china:
            rustServer = FxaServer.china
        case .localdev:
            rustServer = FxaServer.localDev
        }

        rustConfig = FxaConfig(
            server: rustServer,
            clientId: clientId,
            redirectUri: redirectUri,
            tokenServerUrlOverride: tokenServerUrlOverride
        )
    }
}

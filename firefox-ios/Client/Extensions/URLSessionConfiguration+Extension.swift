// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLSessionConfiguration {
    static var defaultMPTCP: URLSessionConfiguration {
        let conf = self.default
        conf.multipathServiceType = .handover
        return conf
    }

    static var ephemeralMPTCP: URLSessionConfiguration {
        let conf = self.ephemeral
        conf.multipathServiceType = .handover
        return conf
    }

    /// Applies the current VPN proxy stack, if any, so requests match the webview's routing.
    func withVPNProxy() -> URLSessionConfiguration {
        if #available(iOS 27.2, *) {
            proxyConfigurations = VPNProxySessionProvider.shared.proxyConfigurations
        }
        return self
    }
}

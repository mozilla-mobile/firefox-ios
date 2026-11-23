// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URLSession {
    static let sharedMPTCP = URLSession(configuration: URLSessionConfiguration.defaultMPTCP)

    /// `URLSession.shared`, or a session routed through the VPN proxy while it is on.
    static var sharedWithVPNProxy: URLSession {
        guard #available(iOS 17.0, *) else { return .shared }
        return VPNProxySessionProvider.shared.session
    }
}

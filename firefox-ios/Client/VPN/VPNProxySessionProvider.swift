// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Network
import Foundation

/// Mirrors the proxy stack applied to WebKit so app-side `URLSession`s route through it too.
@available(iOS 27.2, *)
final class VPNProxySessionProvider: @unchecked Sendable {
    static let shared = VPNProxySessionProvider()

    private let lock = NSLock()
    private var configs: [ProxyConfiguration] = []
    private var proxiedSession: URLSession?

    var proxyConfigurations: [ProxyConfiguration] {
        lock.withLock { configs }
    }

    /// `URLSession.shared` while the proxy is off, otherwise a shared session using the current stack.
    var session: URLSession {
        lock.withLock {
            guard !configs.isEmpty else { return .shared }
            if let proxiedSession { return proxiedSession }
            let configuration = URLSessionConfiguration.default
            configuration.proxyConfigurations = configs
            let session = URLSession(configuration: configuration)
            proxiedSession = session
            return session
        }
    }

    func update(_ configs: [ProxyConfiguration]) {
        let oldSession: URLSession? = lock.withLock {
            self.configs = configs
            defer { proxiedSession = nil }
            return proxiedSession
        }
        oldSession?.finishTasksAndInvalidate()
    }
}

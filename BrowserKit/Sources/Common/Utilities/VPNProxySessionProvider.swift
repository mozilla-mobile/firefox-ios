// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Network
import Foundation

/// Mirrors the proxy stack applied to WebKit so app-side `URLSession`s route through it too.
@available(iOS 17.0, *)
public final class VPNProxySessionProvider: @unchecked Sendable {
    public static let shared = VPNProxySessionProvider()

    private let lock = NSLock()
    private var configs: [ProxyConfiguration] = []
    private var proxiedSession: URLSession?

    init() {}

    public var proxyConfigurations: [ProxyConfiguration] {
        lock.withLock { configs }
    }

    public var isProxyActive: Bool {
        lock.withLock { !configs.isEmpty }
    }

    /// `URLSession.shared` while the proxy is off, otherwise a shared session using the current stack.
    public var session: URLSession {
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

    public func update(_ configs: [ProxyConfiguration]) {
        let oldSession: URLSession? = lock.withLock {
            self.configs = configs
            defer { proxiedSession = nil }
            return proxiedSession
        }
        oldSession?.finishTasksAndInvalidate()
    }
}

public extension URLSessionConfiguration {
    /// Applies the current VPN proxy stack, if any, so requests match the webview's routing.
    func withVPNProxy() -> URLSessionConfiguration {
        if #available(iOS 17.0, *) {
            proxyConfigurations = VPNProxySessionProvider.shared.proxyConfigurations
        }
        return self
    }
}

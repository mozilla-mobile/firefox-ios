// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import MozillaAppServices
import Network
import WebEngine

@MainActor
protocol VPNManaging {
    var isRunning: Bool { get }
    func start() async
    func stop() async
}

enum VPNError: Error {
    case notSignedIn
    case noServerFound
}

@available(iOS 26.0, *)
final class VPNManager: VPNManaging {
    private static let secretKey = "VPNGuardianSecret"

    private let logger: Logger
    private let guardian: VPNGuardian
    private let windowManager: WindowManager

    private(set) var isRunning = false
    private var activeServer: VPNGuardian.Server?
    private var rotationTask: Task<Void, Never>?

    init(
        logger: Logger = DefaultLogger.shared,
        clientConfig: VPNGuardian.Configuration = .staging,
        windowManager: WindowManager = AppContainer.shared.resolve()
    ) {
        self.logger = logger
        self.guardian = VPNGuardian(
            authHeaders: Self.guardianAuthHeaders(logger: logger),
            configuration: clientConfig,
            logger: logger
        )
        self.windowManager = windowManager
    }

    /// Guardian's shared auth secret, supplied at runtime via the `VPN_GUARDIAN_SECRET` environment
    /// variable so it never lands in source control. Set it on the Run action of a local, unshared
    /// copy of the Fennec scheme — the shared schemes are tracked in git, `xcuserdata` is not.
    private static func guardianAuthHeaders(logger: Logger) -> [String: String] {
        let secret = Bundle.main.object(forInfoDictionaryKey: secretKey) as? String
        guard let secret, !secret.isEmpty else {
            logger.log(
                "\(secretKey) is unset — Guardian pass requests will fail to authenticate",
                level: .warning,
                category: .settings
            )
            return [:]
        }
        return ["secret": secret]
    }

    func start() async {
        do {
            let pass = try await self.guardian.getPass()

            // Hardcode server to point at staging for this foxfooding
            let server = VPNGuardian.Server(hostname: "stage.m1.fastly-masque.net", port: 2499, city: "", countryCode: "")

            self.logger.log(
                "Got Guardian proxy pass — expires \(pass.expiresAt), usage \(String(describing: pass.usage)); server \(server.hostname):\(server.port) (\(server.city), \(server.countryCode))",
                level: .info,
                category: .sync
            )
            let config = self.buildProxyConfig(server: server, pass: pass)
            await self.applyProxyAndRebuildWebViews(configs: [config])
            self.activeServer = server
            self.isRunning = true
            self.startPassRotation(after: pass)
        } catch {
            self.logger.log("VPN start failed: \(error)", level: .warning, category: .sync)
        }
    }

    func stop() async {
        self.rotationTask?.cancel()
        self.rotationTask = nil
        await self.applyProxyAndRebuildWebViews(configs: [])
        self.activeServer = nil
        self.isRunning = false
    }

    /// Consumes `VPNGuardian.passRotation` and reapplies the proxy configuration with the
    /// new bearer token. We use the lightweight `applyProxyConfigurations` (not
    /// `rebuildStores`) here — the proxy endpoint is unchanged so we want to keep WebKit's
    /// existing connection pool, letting in-flight requests finish under the proxy's grace
    /// period while new requests pick up the rotated header.
    private func startPassRotation(after initial: VPNGuardian.ProxyPass) {
        rotationTask?.cancel()
        rotationTask = Task { [weak self] in
            guard let stream = self?.guardian.passRotation(after: initial) else { return }
            for await new in stream {
                guard let self,
                      let server = self.activeServer else { return }
                let config = self.buildProxyConfig(server: server, pass: new)
                DefaultWKEngineConfigurationProvider.applyProxyConfigurations([config], scope: .normal)
                self.logger.log(
                    "Rotated VPN proxy pass — next expiry \(new.expiresAt)",
                    level: .info,
                    category: .sync
                )
            }
        }
    }

    /// Swap the WebKit data store to one with the new proxy configuration applied, then tear
    /// down every normal tab's webview against the old store and reload the visible tab.
    /// Assigning `proxyConfigurations` on an existing store does not invalidate WebKit's
    /// connection pool, so without a swap, in-flight or pooled connections bypass the proxy.
    ///
    /// Deliberately scoped to `.normal`
    private func applyProxyAndRebuildWebViews(configs: [ProxyConfiguration]) async {
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations(configs, scope: .normal)
        await rebuildWebViews()
    }

    private func rebuildWebViews() async {
        for tabManager in windowManager.allWindowTabManagers() {
            await tabManager.cleanupWebViewsForProxyChange()
        }
    }

    private func buildProxyConfig(server: VPNGuardian.Server, pass: VPNGuardian.ProxyPass) -> ProxyConfiguration {
        var components = URLComponents()
        components.scheme = "https"
        components.host = server.hostname
        components.port = Int(server.port)
        let endpoint = NWEndpoint.url(components.url!)
        let hop = ProxyConfiguration.RelayHop(
            http3RelayEndpoint: endpoint,
            http2RelayEndpoint: endpoint,
            tlsOptions: NWProtocolTLS.Options(),
            additionalHTTPHeaderFields: [
                "Proxy-Authorization": "Bearer \(pass.bearerToken)"
            ]
        )
        return ProxyConfiguration(relayHops: [hop])
    }
}

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
    func start(privateOnly: Bool) async
    func stop() async
}

enum VPNError: Error {
    case notSignedIn
    case noServerFound
}

@available(iOS 26.0, *)
final class VPNManager: VPNManaging {
    private static let secretEnvKey = "VPN_GUARDIAN_SECRET"

    private let logger: Logger
    private let guardian: VPNGuardian
    private let serverlist: VPNServerlist
    private let windowManager: WindowManager

    private(set) var isRunning = false
    private var activeServer: VPNGuardian.Server?
    private var activeScope: ProxyScope?
    private var rotationTask: Task<Void, Never>?

    init(
        logger: Logger = DefaultLogger.shared,
        rsService: RemoteSettingsService = (AppContainer.shared.resolve() as Profile).remoteSettingsService,
        clientConfig: VPNGuardian.Configuration = .staging,
        windowManager: WindowManager = AppContainer.shared.resolve(),
        urlSession: URLSessionProtocol = URLSession.shared
    ) {
        self.logger = logger
        self.guardian = VPNGuardian(
            authHeaders: Self.guardianAuthHeaders(logger: logger),
            configuration: clientConfig,
            logger: logger
        )
        self.serverlist = VPNServerlist(rsService: rsService, logger: logger)
        self.windowManager = windowManager
    }

    /// Guardian's shared auth secret, supplied at runtime via the `VPN_GUARDIAN_SECRET` environment
    /// variable so it never lands in source control. Set it on the Run action of a local, unshared
    /// copy of the Fennec scheme — the shared schemes are tracked in git, `xcuserdata` is not.
    private static func guardianAuthHeaders(logger: Logger) -> [String: String] {
        guard let secret = ProcessInfo.processInfo.environment[secretEnvKey], !secret.isEmpty else {
            logger.log(
                "\(secretEnvKey) is unset — Guardian pass requests will fail to authenticate",
                level: .warning,
                category: .sync
            )
            return [:]
        }
        return ["secret": secret]
    }

    func start(privateOnly: Bool = false) async {
        do {
            let pass = try await self.guardian.getPass()
            guard let server = self.serverlist.selectServer() else {
                throw VPNError.noServerFound
            }

            self.logger.log(
                "Got Guardian proxy pass — expires \(pass.expiresAt), usage \(String(describing: pass.usage)); server \(server.hostname):\(server.port) (\(server.city), \(server.countryCode))",
                level: .info,
                category: .sync
            )
            let config = self.buildProxyConfig(server: server, pass: pass)
            let scope: ProxyScope = privateOnly ? .private : .normal
            await self.applyProxyAndRebuildWebViews(configs: [config], scope: scope)
            self.activeServer = server
            self.activeScope = scope
            self.isRunning = true
            self.startPassRotation(after: pass)
        } catch {
            self.logger.log("VPN start failed: \(error)", level: .warning, category: .sync)
        }
    }

    func stop() async {
        self.rotationTask?.cancel()
        self.rotationTask = nil
        await self.applyProxyAndRebuildWebViews(configs: [], scope: .normal)
        self.activeServer = nil
        self.activeScope = nil
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
                      let server = self.activeServer,
                      let scope = self.activeScope else { return }
                let config = self.buildProxyConfig(server: server, pass: new)
                DefaultWKEngineConfigurationProvider.applyProxyConfigurations([config], scope: scope)
                self.logger.log(
                    "Rotated VPN proxy pass — next expiry \(new.expiresAt)",
                    level: .info,
                    category: .sync
                )
            }
        }
    }

    /// Swap the WebKit data stores to ones with the new proxy configuration applied, then
    /// tear down every tab's webview against the old store and reload the visible tab.
    /// Assigning `proxyConfigurations` on an existing store does not invalidate WebKit's
    /// connection pool, so without a swap, in-flight or pooled connections bypass the proxy.
    private func applyProxyAndRebuildWebViews(configs: [ProxyConfiguration], scope: ProxyScope) async {
        await DefaultWKEngineConfigurationProvider.rebuildStores(
            applyingProxy: configs,
            scope: scope
        )
        for tabManager in windowManager.allWindowTabManagers() {
            await tabManager.cleanupWebViewsForProxyChange()
        }
        // Safe to free the displaced stores' disk footprint now that every webview holding
        // them has been torn down.
        await DefaultWKEngineConfigurationProvider.removeStaleStores()
    }

    private func buildProxyConfig(server: VPNGuardian.Server, pass: VPNGuardian.ProxyPass) -> ProxyConfiguration {
        var components = URLComponents()
        components.scheme = "https"
        components.host = server.hostname
        components.port = Int(server.port)
        let endpoint = NWEndpoint.url(components.url!)
        let hop = ProxyConfiguration.RelayHop(
            http2RelayEndpoint: endpoint,
            // TODO: http3RelayEndpoint bricks it, we get quic errors, need to reach out to fstly
            tlsOptions: NWProtocolTLS.Options(),
            additionalHTTPHeaderFields: [
                "Proxy-Authorization": "Bearer \(pass.bearerToken)"
            ]
        )
        return ProxyConfiguration(relayHops: [hop])
    }
}

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
protocol VPNRunnable {
    var isRunning: Bool { get }
    func start() async
    func stop() async
}

enum VPNError: Error {
    case notSignedIn
    case noServerFound
}

@available(iOS 17.0, *)
@MainActor
protocol ProxyConfigurator {
    func applyProxyConfigurations(_ configs: [ProxyConfiguration], forcingSessionReset: Bool)
}

@available(iOS 17.0, *)
struct DefaultProxyConfigurator: ProxyConfigurator {
    func applyProxyConfigurations(_ configs: [ProxyConfiguration], forcingSessionReset: Bool) {
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations(configs, forcingSessionReset: forcingSessionReset)
    }
}

@available(iOS 17.0, *)
final class VPNManager: VPNRunnable, UserFeaturePreferenceProvider {
    private static let secretKey = "VPNGuardianSecret"
    private let logger: Logger
    private let guardian: VPNGuardianProviding
    private let serverManager: VPNServerManaging
    private let windowManager: WindowManager
    private let proxyApplier: ProxyConfigurator

    // TODO: fxios-16876 This will get used when we wire up VPN Connection
    var isRunning: Bool {
        userPreferences.getPreferenceFor(.vpnFeature)
    }

    private var activeServer: VPNGuardian.Server?
    private var rotationTask: Task<Void, Never>?

    init(
        logger: Logger = DefaultLogger.shared,
        clientConfig: VPNGuardian.Configuration = .staging,
        profile: Profile = AppContainer.shared.resolve(),
        windowManager: WindowManager = AppContainer.shared.resolve(),
        guardian: VPNGuardianProviding? = nil,
        serverManager: VPNServerManaging? = nil,
        proxyApplier: ProxyConfigurator = DefaultProxyConfigurator()
    ) {
        self.logger = logger
        self.guardian = guardian ?? VPNGuardian(
            authHeaders: Self.guardianAuthHeaders(logger: logger),
            configuration: clientConfig,
            logger: logger
        )
        self.serverManager = serverManager ?? VPNServerManager(
            client: profile.remoteSettingsService.makeClient(collectionName: VPNServerManager.collectionName),
            logger: logger
        )
        self.windowManager = windowManager
        self.proxyApplier = proxyApplier
    }

    func start() async {
        do {
            let pass = try await self.guardian.getPass()

            guard let server = await self.serverManager.selectServer(countryCode: nil) else {
                throw VPNError.noServerFound
            }

            self.logger.log(
                "Got Guardian proxy pass — expires \(pass.expiresAt), usage \(String(describing: pass.usage)); server \(server.hostname):\(server.port) (\(server.city), \(server.countryCode))",
                level: .info,
                category: .sync
            )
            let config = self.buildProxyConfig(server: server, pass: pass)
            await self.applyProxyAndRebuildWebViews(configs: [config])
            self.activeServer = server
            self.userPreferences.setPreferenceFor(.vpnFeature, to: true)
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
        self.userPreferences.setPreferenceFor(.vpnFeature, to: false)
    }

    // TODO: FXIOS-16874 This will go away with VPNKit integration.
    // Guardian's shared auth secret, supplied at runtime via the `VPN_GUARDIAN_SECRET` environment
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

    /// Consumes `VPNGuardian.passRotation` and reapplies the proxy configuration with the new
    /// bearer token. The endpoint is unchanged, so this rotates without forcing a session
    /// reset: WebKit keeps its existing connection pool, in-flight requests finish under the
    /// proxy's grace period, and new requests pick up the rotated header. Forcing the reset
    /// here would tear down sessions out from under webviews that are still loading.
    private func startPassRotation(after initial: VPNGuardian.ProxyPass) {
        rotationTask?.cancel()
        rotationTask = Task { [weak self] in
            guard let stream = self?.guardian.passRotation(after: initial) else { return }
            for await new in stream {
                guard let self,
                      let server = self.activeServer else { return }
                let config = self.buildProxyConfig(server: server, pass: new)
                self.proxyApplier.applyProxyConfigurations([config], forcingSessionReset: false)
                self.logger.log(
                    "Rotated VPN proxy pass — next expiry \(new.expiresAt)",
                    level: .info,
                    category: .sync
                )
            }
        }
    }

    /// Tear down every webview, wait for WebKit to process the resulting load cancellations,
    /// then apply the new proxy configuration and rebuild the visible tab.
    ///
    /// Order is necessary here. Assigning `proxyConfigurations` does not invalidate WebKit's
    /// existing connection pool, so the webviews holding it have to be discarded for the change
    /// to take effect — but discarding them cancels every load they own, and a cancellation that
    /// lands after the stack changed is processed against a session WebKit has already torn
    /// down, which takes the network process with it.
    private func applyProxyAndRebuildWebViews(configs: [ProxyConfiguration]) async {
        await tearDownWebViews()
        proxyApplier.applyProxyConfigurations(configs, forcingSessionReset: true)
        restoreSelectedTabs()
    }

    private func tearDownWebViews() async {
        for tabManager in windowManager.allWindowTabManagers() {
            await tabManager.tearDownWebViewsForProxyChange()
        }
    }

    private func restoreSelectedTabs() {
        for tabManager in windowManager.allWindowTabManagers() {
            tabManager.restoreSelectedTabForProxyChange()
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

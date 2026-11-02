// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import MozillaAppServices
import Network
import VPNKit
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
    case proxyURLCannotBeGenerated
    case tokenProviderUnavailable
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
    private let logger: Logger
    private let environment: VPNEnvironment
    private let guardian: VPNGuardianProviding?
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
        profile: Profile = AppContainer.shared.resolve(),
        windowManager: WindowManager = AppContainer.shared.resolve(),
        guardian: VPNGuardianProviding? = nil,
        authCreator: VPNAuthCreating = VPNAuthCreator(),
        serverManager: VPNServerManaging? = nil,
        proxyApplier: ProxyConfigurator = DefaultProxyConfigurator()
    ) {
        self.logger = logger
        self.environment = VPNEnvironment(prefs: profile.prefs)
        self.guardian = guardian ?? VPNGuardian(authCreator: authCreator, prefs: profile.prefs, logger: logger)
        self.serverManager = serverManager ?? VPNServerManager(
            client: profile.remoteSettingsService.makeClient(collectionName: VPNServerManager.collectionName),
            logger: logger
        )
        self.windowManager = windowManager
        self.proxyApplier = proxyApplier
    }

    func start() async {
        do {
            guard let guardian = self.guardian else {
                throw VPNError.tokenProviderUnavailable
            }

            let pass = try await guardian.getPass()

            // TODO: FXIOS-16873 When we implement location selection it will be passed in here
            guard let server = await serverManager.selectServer(countryCode: nil, environment: environment) else {
                throw VPNError.noServerFound
            }

            self.logger.log(
                "Got Guardian proxy pass — expires \(pass.expiresAt), usage \(String(describing: pass.usage)); server \(server.hostname):\(server.port) (\(server.city), \(server.countryCode))",
                level: .info,
                category: .vpn
            )
            let config = try self.buildProxyConfig(server: server, pass: pass)
            await self.applyProxyAndRebuildWebViews(configs: [config])
            self.activeServer = server
            self.userPreferences.setPreferenceFor(.vpnFeature, to: true)
            self.startPassRotation(after: pass)
            self.showDataLimitAlertIfNeeded(for: pass)
        } catch {
            self.logger.log("VPN start failed: \(error)", level: .warning, category: .vpn)
        }
    }

    func stop() async {
        self.rotationTask?.cancel()
        self.rotationTask = nil
        await self.applyProxyAndRebuildWebViews(configs: [])
        self.activeServer = nil
        self.userPreferences.setPreferenceFor(.vpnFeature, to: false)
    }

    /// Consumes `VPNGuardian.passRotation` and reapplies the proxy configuration with the new
    /// bearer token. The endpoint is unchanged, so this rotates without forcing a session
    /// reset: WebKit keeps its existing connection pool, in-flight requests finish under the
    /// proxy's grace period, and new requests pick up the rotated header. Forcing the reset
    /// here would tear down sessions out from under webviews that are still loading.
    private func startPassRotation(after initial: VPNProxyPass) {
        rotationTask?.cancel()
        rotationTask = Task { [weak self] in
            guard let stream = self?.guardian?.passRotation(after: initial) else { return }
            do {
                for try await new in stream {
                    guard let self,
                          let server = self.activeServer else { return }
                    let config = try self.buildProxyConfig(server: server, pass: new)
                    self.proxyApplier.applyProxyConfigurations([config], forcingSessionReset: false)
                    self.showDataLimitAlertIfNeeded(for: new)
                    self.logger.log(
                        "Rotated VPN proxy pass — next expiry \(new.expiresAt)",
                        level: .info,
                        category: .vpn
                    )
                }
            } catch {
                self?.logger.log(
                    "Pass rotation failed terminally, stopping rotation: \(error)",
                    level: .warning,
                    category: .vpn
                )
                self?.showFailureAlert()
            }
        }
    }

    private func showFailureAlert() {
        guard let windowUUID = alertWindowUUID() else { return }
        store.dispatch(
            GeneralBrowserAction(
                windowUUID: windowUUID,
                actionType: GeneralBrowserActionType.showVPNFailureAlert
            )
        )
    }

    private func showDataLimitAlertIfNeeded(for pass: VPNProxyPass) {
        guard let usage = pass.usage,
              !usage.unlimited,
              usage.remaining <= 0,
              let windowUUID = alertWindowUUID() else { return }
        store.dispatch(
            GeneralBrowserAction(
                vpnDataLimitBytes: usage.max,
                windowUUID: windowUUID,
                actionType: GeneralBrowserActionType.showVPNDataLimitAlert
            )
        )
    }

    /// The foreground window, falling back to any open window, so VPN alerts only show once.
    private func alertWindowUUID() -> WindowUUID? {
        let windows = windowManager.windows
        let activeWindowUUID = windows.first {
            $0.value.sceneCoordinator?.window?.windowScene?.activationState == .foregroundActive
        }?.key
        return activeWindowUUID ?? windows.keys.first
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

    private func buildProxyConfig(server: VPNGuardian.Server, pass: VPNProxyPass) throws -> ProxyConfiguration {
        var components = URLComponents()
        components.scheme = "https"
        components.host = server.hostname
        components.port = Int(server.port)
        guard let url = components.url else {
            throw VPNError.proxyURLCannotBeGenerated
        }
        let endpoint = NWEndpoint.url(url)
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

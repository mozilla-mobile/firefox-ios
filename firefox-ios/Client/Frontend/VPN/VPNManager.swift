// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import MozillaAppServices
import Network
import UIKit
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

@available(iOS 17.0, *)
final class VPNManager: VPNManaging, Notifiable {
    private static let secretKey = "VPNGuardianSecret"

    private let logger: Logger
    private let guardian: VPNGuardian
    private let serverlist: VPNServerlist
    private let prefs: Prefs
    private let windowManager: WindowManager
    private let userPreferences: UserFeaturePreferring
    private let notificationCenter: NotificationProtocol

    var isRunning: Bool {
        self.userPreferences.getPreferenceFor(.vpnFeature)
    }

    private var activeServer: VPNGuardian.Server?
    private var currentPass: VPNGuardian.ProxyPass?
    private var rotationTask: Task<Void, Never>?
    private var foregroundRefreshTask: Task<Void, Never>?

    init(
        logger: Logger = DefaultLogger.shared,
        clientConfig: VPNGuardian.Configuration = .prod,
        profile: Profile = AppContainer.shared.resolve(),
        windowManager: WindowManager = AppContainer.shared.resolve(),
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.logger = logger
        self.guardian = VPNGuardian(
            authHeaders: Self.guardianAuthHeaders(logger: logger),
            configuration: clientConfig,
            logger: logger
        )
        self.serverlist = VPNServerlist(rsService: profile.remoteSettingsService, logger: logger)
        self.prefs = profile.prefs
        self.windowManager = windowManager
        self.userPreferences = userPreferences
        self.notificationCenter = notificationCenter

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIApplication.willEnterForegroundNotification]
        )
    }

    func handleNotifications(_ notification: Notification) {
        let name = notification.name
        ensureMainThread {
            switch name {
            case UIApplication.willEnterForegroundNotification:
                self.refreshPassIfNeeded()
            default: break
            }
        }
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

            let countryCode = self.prefs.stringForKey(PrefsKeys.Settings.vpnLocation)
            guard let server = await self.serverlist.selectServer(countryCode: countryCode) else {
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
            self.currentPass = pass
            self.userPreferences.setPreferenceFor(.vpnFeature, to: true)
            self.startPassRotation(after: pass)
        } catch {
            self.logger.log("VPN start failed: \(error)", level: .warning, category: .sync)
        }
    }

    func stop() async {
        self.rotationTask?.cancel()
        self.rotationTask = nil
        self.foregroundRefreshTask?.cancel()
        self.foregroundRefreshTask = nil
        await self.applyProxyAndRebuildWebViews(configs: [])
        self.activeServer = nil
        self.currentPass = nil
        self.userPreferences.setPreferenceFor(.vpnFeature, to: false)
    }

    /// Rotation can't run while the app is suspended, so the pass may have expired in the
    /// background. The proxy's grace period only covers live connections, so new ones made on
    /// foreground would fail with the stale token. Rotate immediately if the pass is due.
    private func refreshPassIfNeeded() {
        guard foregroundRefreshTask == nil, let staleServer = activeServer, let stalePass = currentPass else { return }
        let refreshAt = stalePass.expiresAt.addingTimeInterval(-VPNGuardian.rotateBeforeExpiry)
        guard refreshAt <= Date() else { return }

        rotationTask?.cancel()
        rotationTask = nil
        foregroundRefreshTask = Task { [weak self] in
            guard let self else { return }
            defer { self.foregroundRefreshTask = nil }
            do {
                let new = try await self.guardian.rotatePass()
                // Bail if the VPN was stopped or restarted while fetching.
                guard self.currentPass?.bearerToken == stalePass.bearerToken else { return }
                self.applyRotatedPass(new, server: staleServer)
                self.startPassRotation(after: new)
            } catch is CancellationError {
                return
            } catch {
                self.handleRotationFailure(error)
            }
        }
    }

    /// Consumes `VPNGuardian.passRotation` and reapplies the proxy configuration with the new
    /// bearer token. The endpoint is unchanged, so this rotates without forcing a session
    /// reset: WebKit keeps its existing connection pool, in-flight requests finish under the
    /// proxy's grace period, and new requests pick up the rotated header. Forcing the reset
    /// here would tear down sessions out from under webviews that are still loading.
    private func startPassRotation(after initial: VPNGuardian.ProxyPass) {
        rotationTask?.cancel()
        rotationTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await new in self.guardian.passRotation(after: initial) {
                    guard let server = self.activeServer else { return }
                    self.applyRotatedPass(new, server: server)
                }
            } catch {
                self.handleRotationFailure(error)
            }
        }
    }

    private func applyRotatedPass(_ pass: VPNGuardian.ProxyPass, server: VPNGuardian.Server) {
        let config = buildProxyConfig(server: server, pass: pass)
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations(
            [config],
            forcingSessionReset: false
        )
        currentPass = pass
        logger.log(
            "Rotated VPN proxy pass — next expiry \(pass.expiresAt)",
            level: .info,
            category: .sync
        )
    }

    private func handleRotationFailure(_ error: Error) {
        logger.log(
            "Pass rotation failed terminally, stopping rotation: \(error)",
            level: .warning,
            category: .sync
        )
        store.dispatch(
            GeneralBrowserAction(
                windowUUID: .unavailable,
                actionType: GeneralBrowserActionType.showVPNFailureAlert
            )
        )
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
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations(configs)
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

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import MozillaAppServices
import Network
import Observation
import VPNKit
import WebEngine

/// Changes `VPNManager` reports so `VPNMiddleware` can decide which side effects to trigger.
enum VPNEvent: Equatable {
    /// A pass was applied, either on start or rotation.
    case passUpdated(VPNProxyPass)
    case rotationFailed
    /// Guardian refused a pass because the monthly bandwidth quota is used up.
    case quotaExceeded(VPNProxyUsage)
    case connectionFailed
    /// The selected location had no usable server, so a fallback server was used instead.
    case selectedLocationUnavailable
}

@MainActor
protocol VPNRunnable {
    var isRunning: Bool { get }
    var isConnecting: Bool { get }
    var usedDataInGB: Double { get }
    var dataLimitInGB: Double { get }
    var usageFraction: Double { get }
    var isLimitReached: Bool { get }
    /// True once the stored usage's reset date has passed; false if no usage has been fetched.
    var isUsageResetDue: Bool { get }
    var selectedCountryCode: String { get }
    /// Whether the running connection uses a fallback server because the requested location had none.
    var isUsingFallback: Bool { get }
    /// Single-consumer stream of `VPNEvent`s, observed by `VPNMiddleware`.
    var events: AsyncStream<VPNEvent> { get }
    /// Also switches a running VPN to a new server and pass without stopping it first.
    func start(countryCode: String?) async throws
    func stop() async
    func listCountries() async -> [VPNServerManager.Country]
    /// Fetches the current bandwidth usage, whether or not the VPN is running.
    func refreshUsage() async throws
    /// Redraws views reading `selectedCountryCode` after its pref changes.
    func selectedCountryCodeDidChange(countryCode: String)
    /// Stops pass rotation while the app is backgrounded.
    func pauseRotation()
    /// Restarts pass rotation if the VPN is running, rotating right away if the pass is due.
    func resumeRotation()
}

enum VPNError: Error {
    case notSignedIn
    case noServerFound
    case proxyURLCannotBeGenerated
    case tokenProviderUnavailable
}

@available(iOS 27.2, *)
@MainActor
protocol ProxyConfigurator {
    func applyProxyConfigurations(_ configs: [ProxyConfiguration], forcingSessionReset: Bool)
}

@available(iOS 27.2, *)
struct DefaultProxyConfigurator: ProxyConfigurator {
    func applyProxyConfigurations(_ configs: [ProxyConfiguration], forcingSessionReset: Bool) {
        DefaultWKEngineConfigurationProvider.applyProxyConfigurations(configs, forcingSessionReset: forcingSessionReset)
    }
}

@available(iOS 27.2, *)
@Observable
final class VPNManager: VPNRunnable {
    private let logger: Logger
    private let environment: VPNEnvironment
    private let guardian: VPNGuardianProviding?
    private let serverManager: VPNServerManaging
    private let windowManager: WindowManager
    private let proxyApplier: ProxyConfigurator
    private let prefs: Prefs
    private let eventsContinuation: AsyncStream<VPNEvent>.Continuation
    let events: AsyncStream<VPNEvent>

    private var activeServer: VPNGuardian.Server?
    private(set) var isUsingFallback = false

    var isRunning: Bool {
        activeServer != nil
    }

    private(set) var isConnecting = false

    var selectedCountryCode: String {
        // Used with withMutation(keyPath: ) farther down so that SwiftUI observes this computed property
        access(keyPath: \.selectedCountryCode)
        return prefs.stringForKey(PrefsKeys.VPNSettings.selectedCountryCode) ?? VPNServerManager.recommendedCountryCode
    }

    private var currentUsage: VPNProxyUsage?
    private static let bytesPerGB: UInt64 = 0x1 << 30

    var dataLimitInGB: Double {
        guard let usage = currentUsage else { return 0 }
        return Double(usage.max) / Double(Self.bytesPerGB)
    }

    var usedDataInGB: Double {
        guard let usage = currentUsage else { return 0 }
        return Double(min(max(usage.max - usage.remaining, 0), usage.max)) / Double(Self.bytesPerGB)
    }

    var usageFraction: Double {
        guard let usage = currentUsage, usage.max > 0 else { return 0 }
        return usedDataInGB / dataLimitInGB
    }

    var isLimitReached: Bool {
        guard let usage = currentUsage, !isUsageResetDue else { return false }
        return !usage.unlimited && usage.remaining <= 0
    }

    var isUsageResetDue: Bool {
        guard let usage = currentUsage else { return false }
        return usage.reset <= Date()
    }

    private var rotationTask: Task<Void, Never>?
    /// Most recently applied pass, used to resume rotation when returning to the foreground.
    private var latestPass: VPNProxyPass?
    private var isRotationPaused = false

    init(
        logger: Logger = DefaultLogger.shared,
        profile: Profile = AppContainer.shared.resolve(),
        windowManager: WindowManager = AppContainer.shared.resolve(),
        guardian: VPNGuardianProviding? = nil,
        authCreator: VPNAuthCreating = VPNAuthCreator(telemetry: DefaultVPNTelemetry()),
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
        self.prefs = profile.prefs
        let (events, eventsContinuation) = AsyncStream<VPNEvent>.makeStream()
        self.events = events
        self.eventsContinuation = eventsContinuation
    }

    /// When already running, the proxy stays on the old server until the new one is applied,
    /// so a failure leaves it running as-is.
    func start(countryCode: String?) async throws {
        isConnecting = true
        defer { isConnecting = false }
        do {
            try await connect(countryCode: countryCode)
        } catch VPNAuthError.quotaExceeded(let usage) {
            throw VPNAuthError.quotaExceeded(usage)
        } catch {
            eventsContinuation.yield(.connectionFailed)
            throw error
        }
    }

    private func connect(countryCode: String?) async throws {
        // TODO: FXIOS-17399 Remove simulated VPN failure debug hooks after testing
        try throwIfSimulatingFailure()

        guard let guardian = self.guardian else {
            throw VPNError.tokenProviderUnavailable
        }

        let pass: VPNProxyPass
        do {
            pass = try await guardian.getPass()
        } catch VPNAuthError.quotaExceeded(let usage) {
            currentUsage = usage
            eventsContinuation.yield(.quotaExceeded(usage))
            throw VPNAuthError.quotaExceeded(usage)
        }

        guard var selection = await serverManager.selectServer(countryCode: countryCode, environment: environment) else {
            throw VPNError.noServerFound
        }
        // TODO: FXIOS-17399 Remove simulated VPN failure hooks after testing
        if consumeSimulatedLocationFallback(),
           let fallback = await serverManager.selectServer(countryCode: nil, environment: environment) {
            selection = VPNServerSelection(server: fallback.server, didFallBack: true)
        }
        let server = selection.server

        self.logger.log(
            "Got Guardian proxy pass — expires \(pass.expiresAt), usage \(String(describing: pass.usage)); server \(server.hostname):\(server.port) (\(server.city), \(server.countryCode))",
            level: .info,
            category: .vpn
        )
        let config = try self.buildProxyConfig(server: server, pass: pass)
        await self.applyProxyAndRebuildWebViews(configs: [config])
        self.activeServer = server
        self.isUsingFallback = selection.didFallBack
        self.currentUsage = pass.usage
        self.startPassRotation(after: pass)
        self.eventsContinuation.yield(.passUpdated(pass))
        if selection.didFallBack {
            selectedCountryCodeDidChange(countryCode: server.countryCode)
            self.eventsContinuation.yield(.selectedLocationUnavailable)
        }
    }

    func stop() async {
        self.rotationTask?.cancel()
        self.rotationTask = nil
        self.latestPass = nil
        await self.applyProxyAndRebuildWebViews(configs: [])
        self.activeServer = nil
        self.isUsingFallback = false
    }

    func listCountries() async -> [VPNServerManager.Country] {
        return await serverManager.listCountries()
    }

    func refreshUsage() async throws {
        guard let guardian else {
            throw VPNError.tokenProviderUnavailable
        }
        currentUsage = try await guardian.getUsage()
    }

    func selectedCountryCodeDidChange(countryCode: String) {
        // Needed for SwiftUI to observe changes to computed properties
        withMutation(keyPath: \.selectedCountryCode) {
            prefs.setString(countryCode, forKey: PrefsKeys.VPNSettings.selectedCountryCode)
        }
    }

    /// A rotation started during a background wake can be suspended mid-request, which exhausts
    /// `VPNGuardian.rotationTimeout` and fails the rotation on resume, so rotation only runs in the foreground.
    func pauseRotation() {
        isRotationPaused = true
        rotationTask?.cancel()
        rotationTask = nil
    }

    /// An overdue pass rotates almost immediately, since `passRotation` floors its delay at `minRotationInterval`.
    func resumeRotation() {
        isRotationPaused = false
        guard rotationTask == nil, isRunning, let latestPass else { return }
        startPassRotation(after: latestPass)
    }

    // TODO: FXIOS-17399 Remove simulated VPN failure debug hooks after testing
    /// One-shot debug hook: fails the next connection or location switch.
    private func throwIfSimulatingFailure() throws {
        let key = PrefsKeys.VPNSettings.simulateConnectionFailure
        guard prefs.boolForKey(key) == true else { return }
        prefs.removeObjectForKey(key)
        throw VPNError.noServerFound
    }

    // TODO: FXIOS-17399 Remove simulated VPN failure debug hooks after testing
    /// One-shot debug hook: returns true once if the next location switch should fall back.
    private func consumeSimulatedLocationFallback() -> Bool {
        let key = PrefsKeys.VPNSettings.simulateLocationFallback
        guard isRunning, prefs.boolForKey(key) == true else { return false }
        prefs.removeObjectForKey(key)
        return true
    }

    /// Consumes `VPNGuardian.passRotation` and reapplies the proxy configuration with the new
    /// bearer token. The endpoint is unchanged, so this rotates without forcing a session
    /// reset: WebKit keeps its existing connection pool, in-flight requests finish under the
    /// proxy's grace period, and new requests pick up the rotated header. Forcing the reset
    /// here would tear down sessions out from under webviews that are still loading.
    private func startPassRotation(after initial: VPNProxyPass) {
        latestPass = initial
        rotationTask?.cancel()
        rotationTask = nil
        guard !isRotationPaused else { return }
        rotationTask = Task { [weak self] in
            guard let stream = self?.guardian?.passRotation(after: initial) else { return }
            do {
                for try await new in stream {
                    guard let self,
                          let server = self.activeServer else { return }
                    let config = try self.buildProxyConfig(server: server, pass: new)
                    self.proxyApplier.applyProxyConfigurations([config], forcingSessionReset: false)
                    self.latestPass = new
                    self.currentUsage = new.usage
                    self.eventsContinuation.yield(.passUpdated(new))
                    self.logger.log(
                        "Rotated VPN proxy pass — next expiry \(new.expiresAt)",
                        level: .info,
                        category: .vpn
                    )
                }
            } catch VPNAuthError.quotaExceeded(let usage) {
                self?.logger.log("Pass rotation stopped: quota exceeded", level: .warning, category: .vpn)
                self?.currentUsage = usage
                self?.eventsContinuation.yield(.quotaExceeded(usage))
            } catch {
                self?.logger.log(
                    "Pass rotation failed terminally, stopping rotation: \(error)",
                    level: .warning,
                    category: .vpn
                )
                self?.eventsContinuation.yield(.rotationFailed)
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

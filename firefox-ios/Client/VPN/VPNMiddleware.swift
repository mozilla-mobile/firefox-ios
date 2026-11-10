// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import VPNKit

@MainActor
final class VPNMiddleware {
    private let windowManager: WindowManager
    private let logger: Logger
    private let userPreferences: UserFeaturePreferring
    /// Owned here so the proxy session and its pass rotation live as long as the store.
    private let vpnManager: VPNRunnable?

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
         vpnManager: VPNRunnable? = VPNMiddleware.makeVPNManager()) {
        self.windowManager = windowManager
        self.logger = logger
        self.userPreferences = userPreferences
        self.vpnManager = vpnManager
        Task { [weak self] in
            guard let events = self?.vpnManager?.events else { return }
            for await event in events {
                self?.handleVPNEvent(event)
            }
        }
    }

    /// Only creates a manager where `ProxyConfiguration` is available and the feature is enabled.
    static func makeVPNManager(
        featureFlags: FeatureFlagProviding = AppContainer.shared.resolve()
    ) -> VPNRunnable? {
        guard #available(iOS 17.0, *), featureFlags.isEnabled(.vpnFeature) else { return nil }
        return VPNManager()
    }

    lazy var vpnProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    lazy var modernProvider: MiddlewareClosure<AppState> = { [self] state, action, windowUUID in
        guard let action = action as? VPNModernAction else { return }
        Task {
            await self.handleVPNAction(action, windowUUID: windowUUID)
        }
    }

    lazy var legacyProvider: LegacyMiddlewareClosure<AppState> = { state, action in
        // Does not handle any legacy actions
    }

    private func handleVPNEvent(_ event: VPNEvent) {
        switch event {
        case .passUpdated(let pass):
            guard let usage = pass.usage, !usage.unlimited, usage.remaining <= 0 else { return }
            dispatchAlert(.showDataLimitAlert(dataLimitBytes: usage.max))
        case .rotationFailed:
            dispatchAlert(.showFailureAlert)
        case .selectedLocationUnavailable:
            // TODO: FXIOS-16876 wire up location selection errors
            break
        }
    }

    private func dispatchAlert(_ action: VPNAlertModernAction) {
        guard let windowUUID = alertWindowUUID() else { return }
        store.dispatch(action, forWindowUUID: windowUUID)
    }

    /// The foreground window, falling back to any open window, so VPN alerts only show once.
    private func alertWindowUUID() -> WindowUUID? {
        let windows = windowManager.windows
        let activeWindowUUID = windows.first {
            $0.value.sceneCoordinator?.window?.windowScene?.activationState == .foregroundActive
        }?.key
        return activeWindowUUID ?? windows.keys.first
    }

    /// Alert choices close tabs before stopping, so traffic stays proxied until those tabs are gone and
    /// `stop()` doesn't rebuild webviews for tabs about to be closed.
    private func handleVPNAction(_ action: VPNModernAction, windowUUID: WindowUUID) async {
        switch action {
        case .start:
            await startVPN()
        case .stop, .continueWithoutVPN:
            await stopVPN()
        case .closeThisTab:
            let tabManager = windowManager.tabManager(for: windowUUID)
            if let selectedTab = tabManager?.selectedTab {
                tabManager?.removeTab(selectedTab.tabUUID)
            }
            await stopVPN()
        case .closeAllTabs:
            for tabManager in windowManager.allWindowTabManagers() {
                tabManager.removeAllTabs(isPrivateMode: true)
                tabManager.removeAllTabs(isPrivateMode: false)
            }
            await stopVPN()
        }
    }

    private func startVPN() async {
        guard let vpnManager else {
            logger.log("VPN start with no VPNManager registered", level: .warning, category: .vpn)
            return
        }
        do {
            try await vpnManager.start()
            userPreferences.setPreferenceFor(.vpnFeature, to: true)
        } catch {
            logger.log("VPN start failed: \(error)", level: .warning, category: .vpn)
        }
    }

    private func stopVPN() async {
        guard let vpnManager else {
            logger.log("VPN stop with no VPNManager registered", level: .warning, category: .vpn)
            return
        }
        await vpnManager.stop()
        userPreferences.setPreferenceFor(.vpnFeature, to: false)
    }
}

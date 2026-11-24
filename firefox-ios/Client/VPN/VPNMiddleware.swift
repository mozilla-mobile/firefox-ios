// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import VPNKit

@MainActor
final class VPNMiddleware {
    private let windowManager: WindowManager
    private let prefs: Prefs
    private let logger: Logger
    private let userPreferences: UserFeaturePreferring
    private let telemetry: VPNClientTelemetry
    /// Owned here so the proxy session and its pass rotation live as long as the store.
    private let vpnManager: VPNRunnable?

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
         telemetry: VPNClientTelemetry = DefaultVPNTelemetry(),
         vpnManager: VPNRunnable? = VPNMiddleware.makeVPNManager()) {
        self.windowManager = windowManager
        self.prefs = profile.prefs
        self.logger = logger
        self.userPreferences = userPreferences
        self.telemetry = telemetry
        self.vpnManager = vpnManager
        Task { [weak self] in
            guard let events = self?.vpnManager?.events else { return }
            for await event in events {
                self?.handleVPNEvent(event)
            }
        }
    }

    /// Only returns a manager where `ProxyConfiguration` is available and the feature is enabled.
    /// Resolved from the container so the middleware and VPN settings share the same connection.
    static func makeVPNManager() -> VPNRunnable? {
        guard #available(iOS 17.0, *) else { return nil }
        return AppContainer.shared.resolve() as VPNRunnable
    }

    private var selectedCountryCode: String? {
        prefs.stringForKey(PrefsKeys.VPNSettings.selectedCountryCode)
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
        case .passUpdated:
            break
        case .rotationFailed:
            dispatchAlert(.showFailureAlert)
        case .quotaExceeded(let usage):
            dispatchAlert(.showDataLimitAlert(dataLimitBytes: usage.max))
        case .connectionFailed:
            userPreferences.setPreferenceFor(.vpnFeature, to: vpnManager?.isRunning ?? false)
            dispatchAlert(.showConnectionFailedAlert)
        case .selectedLocationUnavailable:
            dispatchAlert(.showLocationUnavailableAlert)
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
            await startVPN(source: .settings)
        case .stop:
            await stopVPN(source: .settings)
        case .continueWithoutVPN(let alertType):
            telemetry.recordAlertOptionSelected(.continueWithoutVPN, alertType: alertType)
            await stopVPN(source: .continueWithoutVPN)
        case .changeLocation(let countryCode):
            await changeVPNLocation(countryCode)
        case .resetVPNAtLaunch:
            resetVPNAtLaunch()
        case .refreshUsage:
            await refreshVPNUsage()
        case .refreshUsageIfResetDue:
            await refreshVPNUsageIfResetDue()
        case .appDidEnterBackground:
            vpnManager?.pauseRotation()
        case .appDidBecomeActive:
            vpnManager?.resumeRotation()
        case .closeThisTab(let alertType):
            telemetry.recordAlertOptionSelected(.closeThisTab, alertType: alertType)
            let tabManager = windowManager.tabManager(for: windowUUID)
            if let selectedTab = tabManager?.selectedTab {
                tabManager?.removeTab(selectedTab.tabUUID)
            }
            await stopVPN(source: .closeThisTab)
        case .closeAllTabs(let alertType):
            telemetry.recordAlertOptionSelected(.closeAllTabs, alertType: alertType)
            let tabManagers = windowManager.allWindowTabManagers()
            let closedTabsCount = tabManagers.reduce(0) { $0 + $1.tabs.count }
            for tabManager in tabManagers {
                tabManager.removeAllTabs(isPrivateMode: true)
                tabManager.removeAllTabs(isPrivateMode: false)
            }
            await stopVPN(source: .closeAllTabs)
            store.dispatch(
                GeneralBrowserAction(
                    toastType: .vpnClosedTabs(count: closedTabsCount),
                    windowUUID: windowUUID,
                    actionType: GeneralBrowserActionType.showToast
                )
            )
        }
    }

    private func resetVPNAtLaunch() {
        userPreferences.setPreferenceFor(.vpnFeature, to: false)
    }

    private func startVPN(source: VPNConnectionStartSource) async {
        guard let vpnManager else {
            logger.log("VPN start with no VPNManager registered", level: .warning, category: .vpn)
            return
        }
        let telemetryCountryCode = selectedCountryCode ?? VPNServerManager.recommendedCountryCode
        let wasRunning = vpnManager.isRunning
        do {
            try await vpnManager.start(countryCode: selectedCountryCode)
            telemetry.recordConnectionSucceeded(
                source: source,
                countryCode: telemetryCountryCode,
                isUsingFallback: vpnManager.isUsingFallback
            )
            if source == .settings, !wasRunning {
                telemetry.recordVPNSettingChanged(isEnabled: true)
            }
            userPreferences.setPreferenceFor(.vpnFeature, to: vpnManager.isRunning)
            UIAccessibility.post(notification: .announcement, argument: String.VPN.Settings.Connected)
        } catch {
            logger.log("VPN start failed: \(error)", level: .warning, category: .vpn)
            telemetry.recordConnectionFailed(
                source: source,
                countryCode: telemetryCountryCode,
                error: VPNConnectionFailureReason(error)
            )
        }
    }

    private func changeVPNLocation(_ countryCode: String) async {
        guard let vpnManager else {
            logger.log("VPN location change with no VPNManager registered", level: .warning, category: .vpn)
            return
        }
        guard countryCode != vpnManager.selectedCountryCode else { return }
        vpnManager.selectedCountryCodeDidChange(countryCode: countryCode)

        // if the VPN is running when the selected location changes, start a new connection
        guard vpnManager.isRunning else {
            telemetry.recordLocationSelected(countryCode: countryCode, isVPNConnected: false, isUsingFallback: nil)
            return
        }
        do {
            try await vpnManager.start(countryCode: countryCode)
            telemetry.recordLocationSelected(
                countryCode: countryCode,
                isVPNConnected: true,
                isUsingFallback: vpnManager.isUsingFallback
            )
        } catch {
            logger.log("VPN location change failed: \(error)", level: .warning, category: .vpn)
            telemetry.recordLocationSelected(countryCode: countryCode, isVPNConnected: true, isUsingFallback: nil)
        }
    }

    /// Refetches usage only once the stored reset date has passed, so the limit clears after a reset.
    private func refreshVPNUsageIfResetDue() async {
        guard vpnManager?.isUsageResetDue == true else { return }
        await refreshVPNUsage()
    }

    private func refreshVPNUsage() async {
        guard let vpnManager else {
            logger.log("VPN usage refresh with no VPNManager registered", level: .warning, category: .vpn)
            return
        }
        do {
            try await vpnManager.refreshUsage()
        } catch {
            logger.log("VPN usage refresh failed: \(error)", level: .warning, category: .vpn)
        }
    }

    private func stopVPN(source: VPNConnectionStopSource) async {
        guard let vpnManager else {
            logger.log("VPN stop with no VPNManager registered", level: .warning, category: .vpn)
            return
        }
        let wasRunning = vpnManager.isRunning
        await vpnManager.stop()
        telemetry.recordConnectionStopped(source: source)
        if source == .settings, wasRunning {
            telemetry.recordVPNSettingChanged(isEnabled: false)
        }
        userPreferences.setPreferenceFor(.vpnFeature, to: false)
    }
}

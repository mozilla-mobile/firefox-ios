// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

@MainActor
final class VPNMiddleware {
    private let windowManager: WindowManager
    private let logger: Logger

    /// The `VPNManager` is only registered on iOS 17, where `ProxyConfiguration` is available.
    private var vpnManager: VPNRunnable? {
        if let injectedVPNManager { return injectedVPNManager }
        guard #available(iOS 17.0, *) else { return nil }
        return AppContainer.shared.resolve()
    }

    private let injectedVPNManager: VPNRunnable?

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         vpnManager: VPNRunnable? = nil) {
        self.windowManager = windowManager
        self.logger = logger
        self.injectedVPNManager = vpnManager
    }

    lazy var vpnProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    lazy var modernProvider: MiddlewareClosure<AppState> = { [self] state, action, windowUUID in
        // Does not test any modern actions
    }

    lazy var legacyProvider: LegacyMiddlewareClosure<AppState> = { [self] state, action in
        guard let action = action as? VPNAction else { return }
        Task {
            await self.handleFailureAlertAction(action)
        }
    }

    /// Closes tabs before stopping, so traffic stays proxied until those tabs are gone and
    /// `stop()` doesn't rebuild webviews for tabs about to be closed.
    private func handleFailureAlertAction(_ action: VPNAction) async {
        let tabManager = windowManager.tabManager(for: action.windowUUID)

        switch action.actionType {
        case VPNActionType.continueWithoutVPN:
            break
        case VPNActionType.closeThisTab:
            if let selectedTab = tabManager?.selectedTab {
                tabManager?.removeTab(selectedTab.tabUUID)
            }
        case VPNActionType.closeAllTabs:
            tabManager?.removeAllTabs(isPrivateMode: true)
            tabManager?.removeAllTabs(isPrivateMode: false)
        case VPNActionType.closeTabsInAllWindows:
            for tabManager in windowManager.allWindowTabManagers() {
                tabManager.removeAllTabs(isPrivateMode: true)
                tabManager.removeAllTabs(isPrivateMode: false)
            }
        default:
            return
        }

        guard let vpnManager else {
            logger.log("VPN failure alert action with no VPNManager registered", level: .warning, category: .vpn)
            return
        }
        await vpnManager.stop()
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import LocalAuthentication

@MainActor
final class PrivateLockMiddleware: FeatureFlaggable {
    private let prefs: Prefs

    init(profile: Profile = AppContainer.shared.resolve()) {
        prefs = profile.prefs
    }

    lazy var lockProvider: Middleware<AppState> = { state, action in
        if let action = action as? PrivateLockAction {
            self.resolveTabPrivateLockActions(action: action, state: state)
        } else if let action = action as? TabTrayAction {
            self.resolveTabChange(action: action, state: state)
        }
    }

    private func resolveTabPrivateLockActions(action: PrivateLockAction, state: AppState) {
        guard isPrivateLockFeatureEnabled() else {
            Self.unlock(windowUUID: action.windowUUID)
            return
        }

        switch action.actionType {
        case PrivateLockActionType.privateAuthRequested(let reason):
            let browserState = self.browserState(from: state, windowUUID: action.windowUUID)
            let lockState = browserState?.privateLockState
            guard lockState?.auth != .authenticating, lockState?.access == .locked else { return }
            startPrivateTabsAuthFlow(reason: reason, windowUUID: action.windowUUID)
        case PrivateLockActionType.didChangeTrayDisplayContext:
            store.dispatch(PrivateLockMiddlewareAction(
                windowUUID: action.windowUUID,
                actionType: PrivateLockMiddlewareActionType.didChangeTrayDisplayContext,
                trayDisplayContext: action.trayDisplayContext)
            )
        case PrivateLockActionType.didChangeTrayPresentation:
            store.dispatch(PrivateLockMiddlewareAction(
                windowUUID: action.windowUUID,
                actionType: PrivateLockMiddlewareActionType.didChangeTrayDisplayContext,
                trayDisplayContext: action.trayDisplayContext)
            )
            resolveTabTrayPanelTypeChange(panel: action.trayPanelType,
                                          windowUUID: action.windowUUID,
                                          state: state)
        case PrivateLockActionType.didEnterBackground, PrivateLockActionType.willEnterForeground:
            Self.lock(triggeredByFailure: false, windowUUID: action.windowUUID)
        case PrivateLockActionType.didChangePrivateTabsLockSetting:
            let browserState = self.browserState(from: state, windowUUID: action.windowUUID)
            store.dispatch(PrivateLockMiddlewareAction(
                windowUUID: action.windowUUID,
                actionType: PrivateLockMiddlewareActionType.didChangePrivateLockState,
                privatePanelLockState: browserState?.privateLockState.withLastUnlocked(at: nil)
            ))
        default:
            break
        }
    }

    private func resolveTabChange(action: TabTrayAction, state: AppState) {
        switch action.actionType {
        case TabTrayActionType.changePanel:
            resolveTabTrayPanelTypeChange(panel: action.panelType,
                                          windowUUID: action.windowUUID,
                                          state: state)
        default:
            break
        }
    }

    private func resolveTabTrayPanelTypeChange(panel: TabTrayPanelType?,
                                               windowUUID: WindowUUID,
                                               state: AppState) {
        guard let panelType = panel,
              let state = browserState(from: state, windowUUID: windowUUID)
        else { return }

        let privateLockEnabled = isPrivateLockFeatureEnabled()
        store.dispatch(PrivateLockMiddlewareAction(
            windowUUID: windowUUID,
            actionType: PrivateLockMiddlewareActionType.didChangeTabTrayPanelType,
            trayPanelType: panel,
            privateLockEnabled: privateLockEnabled
        ))

        // Only trigger a relock when switching to the private panel,
        // the feature is enabled, we are not already authenticating,
        // and the relock timeout has elapsed
        guard state.didBecomePrivateVisible(afterChangingPanelTo: panelType),
              privateLockEnabled,
              state.privateLockState.auth != .authenticating,
              state.privateLockState.shouldRelockByTime
        else { return }

        store.dispatch(PrivateLockMiddlewareAction(
          windowUUID: windowUUID,
          actionType: PrivateLockMiddlewareActionType.didChangePrivateLockState,
          privatePanelLockState: state.privateLockState.locked()
        ))
    }

    private func startPrivateTabsAuthFlow(reason: String, windowUUID: WindowUUID) {
        store.dispatch(PrivateLockMiddlewareAction(
          windowUUID: windowUUID,
          actionType: PrivateLockMiddlewareActionType.didChangePrivateLockState,
          privatePanelLockState: BrowserViewControllerState.PrivateLockDomainState(access: .locked,
                                                                                   auth: .authenticating,
                                                                                   lastUnlockedAt: nil)
        ))

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            Self.lock(triggeredByFailure: true, windowUUID: windowUUID)
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, authError in
            ensureMainThread {
                if success {
                    Self.unlock(windowUUID: windowUUID)
                } else {
                    Self.lock(triggeredByFailure: true, windowUUID: windowUUID)
                }
            }
        }
    }

    private static func lock(triggeredByFailure: Bool, windowUUID: WindowUUID) {
        store.dispatch(PrivateLockMiddlewareAction(
            windowUUID: windowUUID,
            actionType: PrivateLockMiddlewareActionType.didChangePrivateLockState,
            privatePanelLockState:
                BrowserViewControllerState.PrivateLockDomainState(access: .locked,
                                                                  auth: triggeredByFailure ? .failed : .idle,
                                                                  lastUnlockedAt: nil)
        ))
    }

    private static func unlock(windowUUID: WindowUUID) {
        store.dispatch(PrivateLockMiddlewareAction(
            windowUUID: windowUUID,
            actionType: PrivateLockMiddlewareActionType.didChangePrivateLockState,
            privatePanelLockState: BrowserViewControllerState.PrivateLockDomainState(access: .unlocked,
                                                                                     auth: .idle,
                                                                                     lastUnlockedAt: Date())
        ))
    }

    private func isPrivateLockFeatureEnabled() -> Bool {
        PrivateTabsLockFeatureGate(prefs: prefs).isEnabled
    }

    private func browserState(from appState: AppState, windowUUID: WindowUUID) -> BrowserViewControllerState? {
        appState.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: windowUUID
        )
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import LocalAuthentication

@MainActor
final class PrivateLockMiddleware {
    
    private let prefs: Prefs
    
    init(profile: Profile = AppContainer.shared.resolve()) {
        prefs = profile.prefs
    }
    
    lazy var lockProvider: Middleware<AppState> = { state, action in
        if let action = action as? PrivateLockAction {
            self.resolveTabPrivateLockActions(action: action, state: state)
        }
    }
    
    private func resolveTabPrivateLockActions(action: PrivateLockAction, state: AppState) {
        let shouldLock = prefs.boolForKey(PrefsKeys.Settings.lockPrivateTabs) ?? false
        guard shouldLock else { return }
        
        switch action.actionType {
        case PrivateLockActionType.enteredPrivatePanel:
            store.dispatch(PrivateLockMiddlewareAction(
                windowUUID: action.windowUUID,
                actionType: PrivateLockMiddlewareActionType.setPrivateLockState,
                privatePanelLockState: .lockedPrompt
            ))
        case PrivateLockActionType.requestAuth(let reason):
            let browserState = state.screenState(BrowserViewControllerState.self, for: .browserViewController, window: action.windowUUID)
            guard browserState?.privateLockState != PrivateLockState.authenticating else { return }
            auth(reason: reason, windowUUID: action.windowUUID)
        default:
            break
        }
    }
    
    private func auth(reason: String, windowUUID: WindowUUID) {
        
        store.dispatch(PrivateLockMiddlewareAction(
          windowUUID: windowUUID,
          actionType: PrivateLockMiddlewareActionType.setPrivateLockState,
          privatePanelLockState: .authenticating
        ))
        
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            Self.authFailed(windowUUID: windowUUID)
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, authError in
            Task { @MainActor in
                if success {
                    store.dispatch(PrivateLockMiddlewareAction(
                        windowUUID: windowUUID,
                        actionType: PrivateLockMiddlewareActionType.setPrivateLockState,
                        privatePanelLockState: .unlocked
                    ))
                } else {
                    Self.authFailed(windowUUID: windowUUID)
                }
            }
        }
    }
    
    private static func authFailed(windowUUID: WindowUUID) {
        store.dispatch(PrivateLockMiddlewareAction(
            windowUUID: windowUUID,
            actionType: PrivateLockMiddlewareActionType.setPrivateLockState,
            privatePanelLockState: .failed
        ))
    }
}

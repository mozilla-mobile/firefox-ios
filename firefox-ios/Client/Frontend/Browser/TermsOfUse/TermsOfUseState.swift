// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

struct TermsOfUseState: ScreenState, Equatable, FeatureFlaggable {
    let windowUUID: WindowUUID
    var hasAccepted: Bool
    var wasDismissed: Bool
    var lastShownDate: Date?
    var didShowThisLaunch: Bool

    private var isToUFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.touFeature, checking: .buildOnly)
    }

    var windowUUIDForState: WindowUUID {
        return windowUUID
    }

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.hasAccepted = UserDefaults.standard.bool(forKey: "termsOfUseAccepted")
        self.wasDismissed = UserDefaults.standard.bool(forKey: "termsOfUseDismissed")
        self.lastShownDate = UserDefaults.standard.object(forKey: "termsOfUseLastShownDate") as? Date
        self.didShowThisLaunch = false
    }

    static func defaultState(from state: TermsOfUseState) -> TermsOfUseState {
        return TermsOfUseState(windowUUID: state.windowUUID)
    }

    static let reducer: Reducer<TermsOfUseState> = { state, action in
        var newState = state
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType,
              action.windowUUID == state.windowUUID else { return newState }

        switch type {
        case .markAccepted:
            newState.hasAccepted = true
            newState.wasDismissed = false
            UserDefaults.standard.set(true, forKey: "termsOfUseAccepted")
            UserDefaults.standard.set(false, forKey: "termsOfUseDismissed")
        case .markDismissed:
            newState.wasDismissed = true
            newState.lastShownDate = Date()
            UserDefaults.standard.set(true, forKey: "termsOfUseDismissed")
            UserDefaults.standard.set(newState.lastShownDate, forKey: "termsOfUseLastShownDate")
        case .markShownThisLaunch:
            newState.didShowThisLaunch = true
        }

        return newState
    }

    func shouldShow() -> Bool {
        guard isToUFeatureEnabled else { return false }
        if hasAccepted { return false }

        if let lastShown = lastShownDate {
            let days = Calendar.current.dateComponents([.day], from: lastShown, to: Date()).day ?? 0
            if days >= 3 {
                return true
            }
        }

        return !didShowThisLaunch
    }
}

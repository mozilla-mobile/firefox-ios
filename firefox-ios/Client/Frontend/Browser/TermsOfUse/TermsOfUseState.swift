// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

struct TermsOfUseState: ScreenState, Equatable, FeatureFlaggable {
    struct TermsOfUseDefaultsKeys {
        static let acceptedKey = "termsOfUseAccepted"
        static let dismissedKey = "termsOfUseDismissed"
        static let lastShownKey = "termsOfUseLastShownDate"
    }

    let windowUUID: WindowUUID
    var hasAccepted: Bool
    var wasDismissed: Bool
    var lastShownDate: Date?
    var didShowThisLaunch: Bool

    var userDefaults: UserDefaults = .standard

    private var isToUFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.touFeature, checking: .buildOnly)
    }

    var windowUUIDForState: WindowUUID { windowUUID }

    init(windowUUID: WindowUUID, userDefaults: UserDefaults = .standard) {
        self.windowUUID = windowUUID
        self.userDefaults = userDefaults
        self.hasAccepted = userDefaults.bool(forKey: TermsOfUseDefaultsKeys.acceptedKey)
        self.wasDismissed = userDefaults.bool(forKey: TermsOfUseDefaultsKeys.dismissedKey)
        self.lastShownDate = userDefaults.object(forKey: TermsOfUseDefaultsKeys.lastShownKey) as? Date
        self.didShowThisLaunch = false
    }

    static func defaultState(from state: TermsOfUseState) -> TermsOfUseState {
        return TermsOfUseState(windowUUID: state.windowUUID, userDefaults: state.userDefaults)
    }

    static let reducer: Reducer<TermsOfUseState> = { state, action in
        var newState = state
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType,
              action.windowUUID == state.windowUUID else { return newState }

        let userDefaults = state.userDefaults

        switch type {
        case .markAccepted:
            newState.hasAccepted = true
            newState.wasDismissed = false
            userDefaults.set(true, forKey: TermsOfUseDefaultsKeys.acceptedKey)
            userDefaults.set(false, forKey: TermsOfUseDefaultsKeys.dismissedKey)

        case .markDismissed:
            let now = Date()
            newState.wasDismissed = true
            newState.lastShownDate = now
            userDefaults.set(true, forKey: TermsOfUseDefaultsKeys.dismissedKey)
            userDefaults.set(now, forKey: TermsOfUseDefaultsKeys.lastShownKey)

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
            if days >= 3 { return true }
        }

        return !didShowThisLaunch
    }
}

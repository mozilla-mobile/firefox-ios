// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit

/// State for the World Cup promo card displayed on the homepage.
struct WorldCupSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var shouldShowSection: Bool
    var isMilestone2: Bool
    var hasWorldCupStarted: Bool
    var selectedCountryId: String?
    var matches: [WorldCupMatches]
    var apiError: WorldCupLoadError?
    /// Index into `matches` of the card that should be visible first. Used by
    /// the swipe view so that with no team selected we land on the closest
    /// upcoming match rather than the chronologically latest one.
    var defaultMatchIndex: Int
    var shouldShowConfetti: Bool

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.shouldShowSection = false
        self.isMilestone2 = false
        self.hasWorldCupStarted = false
        self.selectedCountryId = nil
        self.matches = []
        self.apiError = nil
        self.defaultMatchIndex = 0
        self.shouldShowConfetti = false
    }

    private init(
        windowUUID: WindowUUID,
        shouldShowSection: Bool,
        isMilestone2: Bool,
        hasWorldCupStarted: Bool,
        selectedCountryId: String?,
        matches: [WorldCupMatches],
        apiError: WorldCupLoadError?,
        defaultMatchIndex: Int,
        shouldShowConfetti: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldShowSection = shouldShowSection
        self.isMilestone2 = isMilestone2
        self.hasWorldCupStarted = hasWorldCupStarted
        self.selectedCountryId = selectedCountryId
        self.matches = matches
        self.apiError = apiError
        self.defaultMatchIndex = defaultMatchIndex
        self.shouldShowConfetti = shouldShowConfetti
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, windowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        guard let action = action as? WorldCupAction else {
            return state
        }
        switch action.actionType {
        case WorldCupMiddlewareActionType.didUpdate:
            return WorldCupSectionState(
                windowUUID: action.windowUUID,
                shouldShowSection: action.shouldShowHomepageWorldCupSection,
                isMilestone2: action.shouldShowMilestone2,
                hasWorldCupStarted: action.hasWorldCupStarted,
                selectedCountryId: action.selectedCountryId,
                matches: action.matches,
                apiError: action.apiError,
                defaultMatchIndex: action.defaultMatchIndex,
                shouldShowConfetti: action.shouldShowConfetti
            )
        default:
            return state
        }
    }

    static func defaultState(from state: WorldCupSectionState) -> WorldCupSectionState {
        return state
    }
}

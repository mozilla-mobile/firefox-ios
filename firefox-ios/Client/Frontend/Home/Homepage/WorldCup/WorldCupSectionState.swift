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
    var bestMatchIndex: Int

    /// Single source of truth for which card the swipe view should land on the
    /// first time the section is rendered. The timer card is the default only
    /// before the World Cup starts AND when no team is selected — once either
    /// changes, we pick a match card. Before kickoff (any date pre-tournament)
    /// we always land on the first card; only once the tournament has started
    /// do we honor the feed's `bestMatchIndex`. `WorldCupCellFactory` controls
    /// whether the timer is even part of the pages array, and `WorldCupCell`
    /// maps this value onto that array.
    var defaultCard: WorldCupDefaultCard {
        if selectedCountryId == nil && !hasWorldCupStarted {
            return .timer
        }
        guard !matches.isEmpty else { return .timer }
        guard hasWorldCupStarted else { return .match(0) }
        let index = min(max(bestMatchIndex, 0), matches.count - 1)
        return .match(index)
    }

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.shouldShowSection = false
        self.isMilestone2 = false
        self.hasWorldCupStarted = false
        self.selectedCountryId = nil
        self.matches = []
        self.apiError = nil
        self.bestMatchIndex = 0
    }

    private init(
        windowUUID: WindowUUID,
        shouldShowSection: Bool,
        isMilestone2: Bool,
        hasWorldCupStarted: Bool,
        selectedCountryId: String?,
        matches: [WorldCupMatches],
        apiError: WorldCupLoadError?,
        bestMatchIndex: Int
    ) {
        self.windowUUID = windowUUID
        self.shouldShowSection = shouldShowSection
        self.isMilestone2 = isMilestone2
        self.hasWorldCupStarted = hasWorldCupStarted
        self.selectedCountryId = selectedCountryId
        self.matches = matches
        self.apiError = apiError
        self.bestMatchIndex = bestMatchIndex
    }

    static let reducer: Reducer<Self> = { state, action in
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
                bestMatchIndex: action.bestMatchIndex
            )
        default:
            return state
        }
    }

    static func defaultState(from state: WorldCupSectionState) -> WorldCupSectionState {
        return state
    }
}

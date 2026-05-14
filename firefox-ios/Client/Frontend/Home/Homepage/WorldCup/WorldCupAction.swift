// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct WorldCupAction: Action {
    let windowUUID: WindowUUID
    let actionType: any ActionType
    let shouldShowHomepageWorldCupSection: Bool
    let shouldShowMilestone2: Bool
    let selectedCountryId: String?
    let matches: [WorldCupMatches]
    let apiError: WorldCupLoadError?
    /// Index into `matches` of the card the swipe view should land on by
    /// default (closest upcoming match). 0 when irrelevant (single card or
    /// empty).
    let defaultMatchIndex: Int

    init(
        windowUUID: WindowUUID,
        actionType: any ActionType,
        shouldShowHomepageWorldCupSection: Bool = false,
        shouldShowMilestone2: Bool = false,
        selectedCountryId: String? = nil,
        matches: [WorldCupMatches] = [],
        apiError: WorldCupLoadError? = nil,
        defaultMatchIndex: Int = 0
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.shouldShowHomepageWorldCupSection = shouldShowHomepageWorldCupSection
        self.shouldShowMilestone2 = shouldShowMilestone2
        self.selectedCountryId = selectedCountryId
        self.matches = matches
        self.apiError = apiError
        self.defaultMatchIndex = defaultMatchIndex
    }
}

enum WorldCupActionType: ActionType {
    case didChangeHomepageSettings
    case removeHomepageCard
    case selectTeam
    case retryMatchesFetch
}

enum WorldCupMiddlewareActionType: ActionType {
    /// An action that is called by the `WorldCupMiddleware` whenever there is an update on the WorldCup information.
    case didUpdate
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import ModifiedCopy
import Redux

/// State holding the values the homepage needs for telemetry purposes, such as impressions and zero search.
@Copyable
struct HomepageTelemetryState: StateType, Equatable {
    var windowUUID: WindowUUID

    /// FXIOS-11504 - This is mainly used for telemetry for top sites and merino and presenting CFRs.
    /// At this time, we are keeping `isZeroSearch` the same as legacy. However, we should revisit this value
    /// and confirm what the expectation is, as it seems inconsistent. See more details in ticket.
    ///
    /// FXIOS-6203 - Comment from legacy homepage:
    /// `isZeroSearch` is true when the homepage is created from the tab tray, a long press
    /// on the tab bar to open a new tab or by pressing the home page button on the tab bar.
    /// The zero search page, aka when the home page is shown by clicking the url bar from a loaded web page.
    /// This needs to be set properly for telemetry and the contextual pop overs that appears on homepage
    let isZeroSearch: Bool
    let shouldTriggerImpression: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            isZeroSearch: false,
            shouldTriggerImpression: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        isZeroSearch: Bool,
        shouldTriggerImpression: Bool
    ) {
        self.windowUUID = windowUUID
        self.isZeroSearch = isZeroSearch
        self.shouldTriggerImpression = shouldTriggerImpression
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case HomepageActionType.embeddedHomepage:
            return handleEmbeddedHomepageAction(for: state, with: action)
        case GeneralBrowserActionType.didSelectedTabChangeToHomepage:
            return state.copy(shouldTriggerImpression: true)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleEmbeddedHomepageAction(
        for state: HomepageTelemetryState,
        with action: Action
    ) -> HomepageTelemetryState {
        guard let isZeroSearch = (action as? HomepageAction)?.isZeroSearch else {
            return defaultState(from: state)
        }

        return state
            .resetTransientState()
            .copy(isZeroSearch: isZeroSearch)
            .copy(shouldTriggerImpression: false)
    }

    /// `shouldTriggerImpression` is reset since impressions should only be triggered once per action that requests it.
    static func defaultState(from state: HomepageTelemetryState) -> HomepageTelemetryState {
        return HomepageTelemetryState(
            windowUUID: state.windowUUID,
            isZeroSearch: state.isZeroSearch,
            shouldTriggerImpression: false
        )
    }
}

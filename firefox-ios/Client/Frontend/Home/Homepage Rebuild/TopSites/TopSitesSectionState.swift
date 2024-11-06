// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

/// State for the top sites section that is used in the homepage
struct TopSitesSectionState: StateType, Equatable {
    var windowUUID: WindowUUID
    var topSitesData: [TopSiteState]

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            topSitesData: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        topSitesData: [TopSiteState]
    ) {
        self.windowUUID = windowUUID
        self.topSitesData = topSitesData
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(fromPreviousState: state)
        }

        switch action.actionType {
        case TopSitesMiddlewareActionType.retrievedUpdatedSites:
            guard let topSitesAction = action as? TopSitesAction,
                  let sites = topSitesAction.topSites
            else {
                return defaultState(fromPreviousState: state)
            }

            return TopSitesSectionState(
                windowUUID: state.windowUUID,
                topSitesData: sites
            )
        default:
            return defaultState(fromPreviousState: state)
        }
    }

    static func defaultState(fromPreviousState state: TopSitesSectionState) -> TopSitesSectionState {
        return TopSitesSectionState(
            windowUUID: state.windowUUID,
            topSitesData: state.topSitesData
        )
    }
}

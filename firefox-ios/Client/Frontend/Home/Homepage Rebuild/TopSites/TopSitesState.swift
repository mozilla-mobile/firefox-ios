// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

/// State for the top sites section that is used in the homepage
struct TopSitesState: StateType, Equatable {
    var windowUUID: WindowUUID
    var topSitesData: [TopSite]

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            topSitesData: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        topSitesData: [TopSite]
    ) {
        self.windowUUID = windowUUID
        self.topSitesData = topSitesData
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return TopSitesState(
                windowUUID: state.windowUUID,
                topSitesData: state.topSitesData
            )
        }

        switch action.actionType {
        case TopSitesMiddlewareActionType.retrievedUpdatedSites:
            guard let topSitesAction = action as? TopSitesAction,
                  let sites = topSitesAction.topSites
            else {
                return TopSitesState(
                    windowUUID: state.windowUUID,
                    topSitesData: state.topSitesData
                )
            }

            return TopSitesState(
                windowUUID: state.windowUUID,
                topSitesData: sites
            )
        default:
            return TopSitesState(
                windowUUID: state.windowUUID,
                topSitesData: state.topSitesData
            )
        }
    }
}

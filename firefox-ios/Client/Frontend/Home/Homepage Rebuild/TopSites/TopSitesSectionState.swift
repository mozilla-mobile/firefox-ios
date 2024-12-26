// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared

/// State for the top sites section that is used in the homepage
/// The state does not only contain the top sites list, but needs to also know about the number of rows
/// and tiles per row in order to only show a specific amount of the top sites data.
struct TopSitesSectionState: StateType, Equatable {
    var windowUUID: WindowUUID
    var topSitesData: [TopSiteState]
    var numberOfRows: Int
    var numberOfTilesPerRow: Int

    init(profile: Profile = AppContainer.shared.resolve(), windowUUID: WindowUUID) {
        let preferredNumberOfRows = profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows)
        let defaultNumberOfRows = TopSitesRowCountSettingsController.defaultNumberOfRows
        let numberOfRows = Int(preferredNumberOfRows ?? defaultNumberOfRows)

        self.init(
            windowUUID: windowUUID,
            topSitesData: [],
            numberOfRows: numberOfRows,
            numberOfTilesPerRow: 0
        )
    }

    private init(
        windowUUID: WindowUUID,
        topSitesData: [TopSiteState],
        numberOfRows: Int,
        numberOfTilesPerRow: Int
    ) {
        self.windowUUID = windowUUID
        self.topSitesData = topSitesData
        self.numberOfRows = numberOfRows
        self.numberOfTilesPerRow = numberOfTilesPerRow
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case TopSitesMiddlewareActionType.retrievedUpdatedSites:
            guard let topSitesAction = action as? TopSitesAction,
                  let sites = topSitesAction.topSites
            else {
                return defaultState(from: state)
            }

            return TopSitesSectionState(
                windowUUID: state.windowUUID,
                topSitesData: sites,
                numberOfRows: state.numberOfRows,
                numberOfTilesPerRow: state.numberOfTilesPerRow
            )
        case TopSitesActionType.updatedNumberOfRows:
            guard let topSitesAction = action as? TopSitesAction,
                  let numberOfRows = topSitesAction.numberOfRows
            else {
                return defaultState(from: state)
            }

            return TopSitesSectionState(
                windowUUID: state.windowUUID,
                topSitesData: state.topSitesData,
                numberOfRows: numberOfRows,
                numberOfTilesPerRow: state.numberOfTilesPerRow
            )
        case TopSitesActionType.updatedNumberOfTilesPerRow:
            guard let topSitesAction = action as? TopSitesAction,
                  let numberOfTilesPerRow = topSitesAction.numberOfTilesPerRow
            else {
                return defaultState(from: state)
            }

            return TopSitesSectionState(
                windowUUID: state.windowUUID,
                topSitesData: state.topSitesData,
                numberOfRows: state.numberOfRows,
                numberOfTilesPerRow: numberOfTilesPerRow
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: TopSitesSectionState) -> TopSitesSectionState {
        return TopSitesSectionState(
            windowUUID: state.windowUUID,
            topSitesData: state.topSitesData,
            numberOfRows: state.numberOfRows,
            numberOfTilesPerRow: state.numberOfTilesPerRow
        )
    }
}

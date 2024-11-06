// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

final class TopSitesMiddleware {
    private let topSitesManager: TopSitesManager

    init(profile: Profile = AppContainer.shared.resolve()) {
        self.topSitesManager = TopSitesManager(
            googleTopSiteManager: GoogleTopSiteManager(
                prefs: profile.prefs
            )
        )
    }

    lazy var topSitesProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize,
            TopSitesActionType.fetchTopSites:
            self.getTopSitesDataAndUpdateState(for: action)
        default:
            break
        }
    }

    private func getTopSitesDataAndUpdateState(for action: Action) {
        Task {
            let topSites = await topSitesManager.getTopSites()
            store.dispatch(
                TopSitesAction(
                    topSites: topSites,
                    windowUUID: action.windowUUID,
                    actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
                )
            )
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

final class ShortcutsLibraryMiddleware {
    private let topSitesManager: TopSitesManagerInterface

    init(
        profile: Profile = AppContainer.shared.resolve(),
        topSitesManager: TopSitesManagerInterface? = nil,
        searchEnginesManager: SearchEnginesManager = AppContainer.shared.resolve(),
    ) {
        self.topSitesManager = topSitesManager ?? TopSitesManager(
            profile: profile,
            googleTopSiteManager: GoogleTopSiteManager(prefs: profile.prefs),
            topSiteHistoryManager: TopSiteHistoryManager(profile: profile),
            searchEnginesManager: searchEnginesManager
        )
    }

    lazy var shortcutsLibraryProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case ShortcutsLibraryActionType.initialize:
            Task { @MainActor in
                await self.getTopSitesDataAndUpdateState(for: action)
            }
        default:
            break
        }
    }

    @MainActor
    private func getTopSitesDataAndUpdateState(for action: Action) async {
        async let sponsoredSites = await self.topSitesManager.fetchSponsoredSites()
        async let otherSites = await self.topSitesManager.getOtherSites()
        let topSites = await self.topSitesManager.recalculateTopSites(otherSites: otherSites, sponsoredSites: sponsoredSites)
        dispatchTopSitesRetrievedAction(for: action.windowUUID, topSites: topSites)
    }

    private func dispatchTopSitesRetrievedAction(for windowUUID: WindowUUID, topSites: [TopSiteConfiguration]) {
        store.dispatchLegacy(
            ShortcutsLibraryAction(
                topSites: topSites,
                windowUUID: windowUUID,
                actionType: ShortcutsLibraryMiddlewareActionType.retrievedUpdatedSites
            )
        )
    }
}

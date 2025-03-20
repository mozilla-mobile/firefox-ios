// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Storage

final class TopSitesMiddleware {
    private let topSitesManager: TopSitesManagerInterface
    private let homepageTelemetry: HomepageTelemetry
    private let bookmarksTelemetry: BookmarksTelemetry
    private let logger: Logger
    private let profile: Profile

    // Raw data to build top sites with, we may want to revisit and fetch only the number of top sites we want
    // but keeping logic consistent for now
    private var otherSites: [TopSiteConfiguration] = []
    private var sponsoredSites: [Site] = []

    init(
        profile: Profile = AppContainer.shared.resolve(),
        topSitesManager: TopSitesManagerInterface? = nil,
        homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
        bookmarksTelemetry: BookmarksTelemetry = BookmarksTelemetry(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.topSitesManager = topSitesManager ?? TopSitesManager(
            profile: profile,
            googleTopSiteManager: GoogleTopSiteManager(
                prefs: profile.prefs
            ),
            topSiteHistoryManager: TopSiteHistoryManager(profile: profile),
            searchEnginesManager: profile.searchEnginesManager
        )
        self.homepageTelemetry = homepageTelemetry
        self.bookmarksTelemetry = bookmarksTelemetry
        self.logger = logger
        self.profile = profile
    }

    lazy var topSitesProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize:
            self.getTopSitesDataAndUpdateState(for: action)

        case TopSitesActionType.fetchTopSites:
            self.getTopSitesDataAndUpdateState(for: action)

        case TopSitesActionType.toggleShowSponsoredSettings:
            self.getTopSitesDataAndUpdateState(for: action)

        case TopSitesActionType.tapOnHomepageTopSitesCell:
            self.sendOpenTopSitesItemTelemetry(for: action)

        case ContextMenuActionType.tappedOnPinTopSite:
            guard let site = self.getSite(for: action) else { return }
            self.topSitesManager.pinTopSite(site)
            self.homepageTelemetry.sendContextMenuOpenedEventForTopSites(for: .pin)

        case ContextMenuActionType.tappedOnUnpinTopSite:
            guard let site = self.getSite(for: action) else { return }
            self.topSitesManager.unpinTopSite(site)
            self.homepageTelemetry.sendContextMenuOpenedEventForTopSites(for: .unpin)

        case ContextMenuActionType.tappedOnRemoveTopSite:
            guard let site = self.getSite(for: action) else { return }
            self.topSitesManager.removeTopSite(site)
            self.homepageTelemetry.sendContextMenuOpenedEventForTopSites(for: .remove)

        case ContextMenuActionType.tappedOnOpenNewPrivateTab:
            self.sendOpenInPrivateTelemetry(for: action)

        case ContextMenuActionType.tappedOnSettingsAction:
            self.homepageTelemetry.sendContextMenuOpenedEventForTopSites(for: .settings)

        case ContextMenuActionType.tappedOnSponsoredAction:
            self.homepageTelemetry.sendContextMenuOpenedEventForTopSites(for: .sponsoredSupport)
        default:
            break
        }
    }

    private func getSite(for action: Action) -> Site? {
        guard let site = (action as? ContextMenuAction)?.site else {
            self.logger.log(
                "Unable to retrieve site for \(action.actionType)",
                level: .warning,
                category: .homepage
            )
            return nil
        }
        return site
    }

    private func getTopSitesDataAndUpdateState(for action: Action) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    self.otherSites = await self.topSitesManager.getOtherSites()
                    self.updateTopSites(
                        for: action.windowUUID,
                        otherSites: self.otherSites,
                        sponsoredTiles: self.sponsoredSites
                    )
                }
                group.addTask {
                    self.sponsoredSites = await self.topSitesManager.fetchSponsoredSites()
                    self.updateTopSites(
                        for: action.windowUUID,
                        otherSites: self.otherSites,
                        sponsoredTiles: self.sponsoredSites
                    )
                }

                await group.waitForAll()
                updateTopSites(
                    for: action.windowUUID,
                    otherSites: self.otherSites,
                    sponsoredTiles: self.sponsoredSites
                )
            }
        }
    }

    private func updateTopSites(
        for windowUUID: WindowUUID,
        otherSites: [TopSiteConfiguration],
        sponsoredTiles: [Site]
    ) {
        let topSites = self.topSitesManager.recalculateTopSites(
            otherSites: otherSites,
            sponsoredSites: sponsoredSites
        )
        store.dispatch(
            TopSitesAction(
                topSites: topSites,
                windowUUID: windowUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )
    }

    private func sendOpenInPrivateTelemetry(for action: Action) {
        guard case .topSites = (action as? ContextMenuAction)?.section else {
            self.logger.log(
                "Unable to retrieve section for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        homepageTelemetry.sendOpenInPrivateTabEventForTopSites()
    }

    private func sendOpenTopSitesItemTelemetry(for action: Action) {
        guard let config = (action as? TopSitesAction)?.telemetryConfig else {
            self.logger.log(
                "Unable to retrieve config for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        homepageTelemetry
            .sendTopSitesPressedEvent(
                position: config.position,
                tileType: config.tileType,
                isZeroSearch: config.isZeroSearch
            )
        sendBookmarkOpenTelemetry(with: config)
    }

    private func sendBookmarkOpenTelemetry(with config: TopSitesTelemetryConfig) {
        let isBookmarked = profile.places.isBookmarked(url: config.url).value.successValue ?? false
        guard isBookmarked else { return }
        bookmarksTelemetry.openBookmarksSite(eventLabel: .topSites)
    }
}

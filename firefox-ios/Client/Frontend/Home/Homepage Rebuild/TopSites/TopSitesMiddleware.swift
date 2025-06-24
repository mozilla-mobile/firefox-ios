// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Storage

/// Middleware to handle top sites related actions, if this gets too big, should split out the telemetry.
final class TopSitesMiddleware: FeatureFlaggable {
    private let topSitesManager: TopSitesManagerInterface
    private let homepageTelemetry: HomepageTelemetry
    private let bookmarksTelemetry: BookmarksTelemetry
    private let unifiedAdsTelemetry: UnifiedAdsCallbackTelemetry
    private let sponsoredTileTelemetry: SponsoredTileTelemetry
    private let logger: Logger
    private let profile: Profile

    init(
        profile: Profile = AppContainer.shared.resolve(),
        topSitesManager: TopSitesManagerInterface? = nil,
        homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
        bookmarksTelemetry: BookmarksTelemetry = BookmarksTelemetry(),
        unifiedAdsTelemetry: UnifiedAdsCallbackTelemetry = DefaultUnifiedAdsCallbackTelemetry(),
        sponsoredTileTelemetry: SponsoredTileTelemetry = DefaultSponsoredTileTelemetry(),
        searchEnginesManager: SearchEnginesManager = AppContainer.shared.resolve(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.topSitesManager = topSitesManager ?? TopSitesManager(
            profile: profile,
            googleTopSiteManager: GoogleTopSiteManager(
                prefs: profile.prefs
            ),
            topSiteHistoryManager: TopSiteHistoryManager(profile: profile),
            searchEnginesManager: searchEnginesManager
        )
        self.homepageTelemetry = homepageTelemetry
        self.bookmarksTelemetry = bookmarksTelemetry
        self.unifiedAdsTelemetry = unifiedAdsTelemetry
        self.sponsoredTileTelemetry = sponsoredTileTelemetry
        self.logger = logger
        self.profile = profile
    }

    lazy var topSitesProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize,
            HomepageMiddlewareActionType.topSitesUpdated,
            TopSitesActionType.toggleShowSponsoredSettings:
            Task { @MainActor in
                await self.getTopSitesDataAndUpdateState(for: action)
            }
        case TopSitesActionType.topSitesSeen:
            self.handleSponsoredImpressionTracking(for: action)

        case TopSitesActionType.tapOnHomepageTopSitesCell:
            self.handleOpenTopSitesItemTelemetry(for: action)

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

    @MainActor
    private func getTopSitesDataAndUpdateState(for action: Action) async {
        async let sponsoredSites = await self.topSitesManager.fetchSponsoredSites()
        async let otherSites = await self.topSitesManager.getOtherSites()
        let topSites = await self.topSitesManager.recalculateTopSites(otherSites: otherSites, sponsoredSites: sponsoredSites)
        dispatchTopSitesRetrievedAction(for: action.windowUUID, topSites: topSites)
    }

    private func dispatchTopSitesRetrievedAction(for windowUUID: WindowUUID, topSites: [TopSiteConfiguration]) {
        store.dispatchLegacy(
            TopSitesAction(
                topSites: topSites,
                windowUUID: windowUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )
    }

    // MARK: Telemetry
    private func handleSponsoredImpressionTracking(for action: Action) {
        guard let telemetryMetadata = (action as? TopSitesAction)?.telemetryConfig else {
            self.logger.log(
                "Unable to retrieve telemetryMetadata for \(action.actionType)",
                level: .warning,
                category: .homepage
            )
            return
        }

        guard telemetryMetadata.topSiteConfiguration.site.isSponsoredSite else { return }
        if featureFlags.isFeatureEnabled(.unifiedAds, checking: .buildOnly) {
            unifiedAdsTelemetry.sendImpressionTelemetry(tileSite: telemetryMetadata.topSiteConfiguration.site, position: telemetryMetadata.position)
        } else {
            sponsoredTileTelemetry.sendImpressionTelemetry(tileSite: telemetryMetadata.topSiteConfiguration.site, position: telemetryMetadata.position)
        }
    }

    private func sendSponsoredTappedTracking(with topSiteConfig: TopSiteConfiguration, and position: Int) {
        guard topSiteConfig.site.isSponsoredSite else { return }
        if featureFlags.isFeatureEnabled(.unifiedAds, checking: .buildOnly) {
            unifiedAdsTelemetry.sendClickTelemetry(tileSite: topSiteConfig.site, position: position)
        } else {
            sponsoredTileTelemetry.sendClickTelemetry(tileSite: topSiteConfig.site, position: position)
        }
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

    private func handleOpenTopSitesItemTelemetry(for action: Action) {
        guard let telemetryConfig = (action as? TopSitesAction)?.telemetryConfig else {
            self.logger.log(
                "Unable to retrieve config for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        let config = telemetryConfig.topSiteConfiguration
        sendSponsoredTappedTracking(with: config, and: telemetryConfig.position)

        homepageTelemetry
            .sendTopSitesPressedEvent(
                position: telemetryConfig.position,
                tileType: config.getTelemetrySiteType,
                isZeroSearch: telemetryConfig.isZeroSearch
            )
        sendBookmarkOpenTelemetry(with: config.site.url)
    }

    private func sendBookmarkOpenTelemetry(with urlString: String) {
        let isBookmarked = profile.places.isBookmarked(url: urlString).value.successValue ?? false
        guard isBookmarked else { return }
        bookmarksTelemetry.openBookmarksSite(eventLabel: .topSites)
    }
}

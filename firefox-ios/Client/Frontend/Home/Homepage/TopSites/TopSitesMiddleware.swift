// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Storage

/// Middleware to handle top sites related actions, if this gets too big, should split out the telemetry.
@MainActor
final class TopSitesMiddleware {
    private let topSitesManager: TopSitesManagerInterface
    private let homepageTelemetry: HomepageTelemetry
    private let bookmarksTelemetry: BookmarksTelemetry
    private let unifiedAdsTelemetry: UnifiedAdsCallbackTelemetry
    private let featureFlagsProvider: FeatureFlagProviding
    private let logger: Logger
    private let profile: Profile
    private var inFlightHomepageTopSitesFetchWindowIDs = Set<WindowUUID>()
    private var nextTopSitesRefreshID = 0

    init(
        profile: Profile = AppContainer.shared.resolve(),
        topSitesManager: TopSitesManagerInterface? = nil,
        homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
        bookmarksTelemetry: BookmarksTelemetry = BookmarksTelemetry(),
        unifiedAdsTelemetry: UnifiedAdsCallbackTelemetry = DefaultUnifiedAdsCallbackTelemetry(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
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
        self.featureFlagsProvider = featureFlagsProvider
        self.logger = logger
        self.profile = profile
    }

    lazy var topSitesProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize,
            ShortcutsLibraryActionType.initialize,
            HomepageMiddlewareActionType.didBecomeActive,
            HomepageMiddlewareActionType.topSitesUpdated,
            TopSitesActionType.toggleShowSponsoredSettings:
            self.fetchTopSitesDataAndUpdateState(for: action, state: state)
        case TopSitesActionType.topSitesSeen:
            self.handleSponsoredImpressionTracking(for: action)

        case TopSitesActionType.tapOnHomepageTopSitesCell:
            self.handleOpenTopSitesItemTelemetry(for: action)

        case TopSitesActionType.shortcutPinned:
            self.handleShortcutPinnedTelemetry(for: action)

        case TopSitesActionType.shortcutUnpinned:
            self.handleShortcutUnpinnedTelemetry(for: action)

        case ContextMenuActionType.tappedOnPinTopSite:
            guard let site = self.getSite(for: action) else { return }
            self.topSitesManager.pinTopSite(site)
            self.homepageTelemetry.sendContextMenuOpenedEventForTopSites(for: .pin)
            self.homepageTelemetry.sendTopSitesShortcutPinnedEvent(source: .contextMenu)

        case ContextMenuActionType.tappedOnUnpinTopSite:
            self.handleTappedOnUnpinSites(for: action)

        case ContextMenuActionType.tappedOnRemoveTopSite:
            self.handleTappedOnRemoveTopSites(for: action)

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

    private func fetchTopSitesDataAndUpdateState(for action: Action, state: AppState) {
        let refreshID = nextRefreshID()
        let shouldDispatchLocalSitesFirst = shouldDispatchLocalSitesFirst(for: action, state: state)
        // We add an in-flight guard per window in TopSitesMiddleware so `initialize`,
        // `didBecomeActive`, and top-site notifications do not fire parallel sponsored
        // requests on launch/foreground. This is to address issues on slow-networks
        // and not create unnecessary additional pressure.
        let shouldCoalesceRefresh = shouldCoalesceHomepageRefresh(for: action)
        if shouldCoalesceRefresh {
            guard inFlightHomepageTopSitesFetchWindowIDs.insert(action.windowUUID).inserted else {
                logger.log(
                    "\(FreezeDiag.prefix)[TopSites] refresh skipped id=\(refreshID) action=\(action.actionType) window=\(FreezeDiag.shortWindowID(action.windowUUID)) appState=\(FreezeDiag.applicationState) localFirst=\(shouldDispatchLocalSitesFirst) coalesced=true",
                    level: .debug,
                    category: .homepage
                )
                return
            }
        }

        logger.log(
            "\(FreezeDiag.prefix)[TopSites] refresh start id=\(refreshID) action=\(action.actionType) window=\(FreezeDiag.shortWindowID(action.windowUUID)) appState=\(FreezeDiag.applicationState) localFirst=\(shouldDispatchLocalSitesFirst) coalesced=\(shouldCoalesceRefresh)",
            level: .info,
            category: .homepage
        )
        Task { @MainActor in
            defer {
                if shouldCoalesceRefresh {
                    self.inFlightHomepageTopSitesFetchWindowIDs.remove(action.windowUUID)
                }
                self.logger.log(
                    "\(FreezeDiag.prefix)[TopSites] refresh cleanup id=\(refreshID) action=\(action.actionType) window=\(FreezeDiag.shortWindowID(action.windowUUID)) appState=\(FreezeDiag.applicationState)",
                    level: .debug,
                    category: .homepage
                )
            }

            await self.getTopSitesDataAndUpdateState(
                for: action,
                refreshID: refreshID,
                shouldDispatchLocalSitesFirst: shouldDispatchLocalSitesFirst
            )
        }
    }

    private func nextRefreshID() -> Int {
        nextTopSitesRefreshID += 1
        return nextTopSitesRefreshID
    }

    private func shouldCoalesceHomepageRefresh(for action: Action) -> Bool {
        switch action.actionType {
        case HomepageActionType.initialize,
            HomepageMiddlewareActionType.didBecomeActive,
            HomepageMiddlewareActionType.topSitesUpdated:
            return true
        default:
            return false
        }
    }

    private func shouldDispatchLocalSitesFirst(for action: Action, state: AppState) -> Bool {
        switch action.actionType {
        case HomepageActionType.initialize,
            HomepageMiddlewareActionType.didBecomeActive,
            HomepageMiddlewareActionType.topSitesUpdated,
            TopSitesActionType.toggleShowSponsoredSettings:
            let homepageState = HomepageState(appState: state, uuid: action.windowUUID)
            return homepageState.topSitesState.topSitesData.isEmpty
        default:
            return false
        }
    }

    private func handleTappedOnRemoveTopSites(for action: Action) {
        guard let site = self.getSite(for: action) else { return }
        Task { @MainActor in
            await self.topSitesManager.removeTopSite(site)
        }
        self.homepageTelemetry.sendContextMenuOpenedEventForTopSites(for: .remove)
    }

    private func handleTappedOnUnpinSites(for action: Action) {
        guard let site = self.getSite(for: action) else { return }
        Task { @MainActor in
            await self.topSitesManager.unpinTopSite(site)
        }
        self.homepageTelemetry.sendContextMenuOpenedEventForTopSites(for: .unpin)
        self.homepageTelemetry.sendTopSitesShortcutUnpinnedEvent(source: .contextMenu)
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
    private func getTopSitesDataAndUpdateState(
        for action: Action,
        refreshID: Int,
        shouldDispatchLocalSitesFirst: Bool
    ) async {
        if shouldDispatchLocalSitesFirst {
            logger.log(
                "\(FreezeDiag.prefix)[TopSites] localFirst start id=\(refreshID) window=\(FreezeDiag.shortWindowID(action.windowUUID)) appState=\(FreezeDiag.applicationState)",
                level: .debug,
                category: .homepage
            )
            let sponsoredSitesTask = fetchSponsoredSitesInBackground(refreshID: refreshID)
            let otherSites = await self.topSitesManager.getOtherSites()
            let localTopSites = self.topSitesManager.recalculateTopSites(otherSites: otherSites, sponsoredSites: [])
            logger.log(
                "\(FreezeDiag.prefix)[TopSites] localFirst localSites id=\(refreshID) otherCount=\(otherSites.count) localCount=\(localTopSites.count) sponsoredTaskStarted=true",
                level: .debug,
                category: .homepage
            )

            if !localTopSites.isEmpty {
                dispatchTopSitesRetrievedAction(for: action.windowUUID, topSites: localTopSites)
                logger.log(
                    "\(FreezeDiag.prefix)[TopSites] localFirst earlyReturn id=\(refreshID) localCount=\(localTopSites.count) sponsoredTaskStarted=true sponsoredTaskAwaited=false",
                    level: .warning,
                    category: .homepage
                )
                return
            }

            logger.log(
                "\(FreezeDiag.prefix)[TopSites] localFirst awaitingSponsored id=\(refreshID)",
                level: .debug,
                category: .homepage
            )
            let sponsoredSites = await sponsoredSitesTask.value
            let topSites = self.topSitesManager.recalculateTopSites(otherSites: otherSites, sponsoredSites: sponsoredSites)
            logger.log(
                "\(FreezeDiag.prefix)[TopSites] localFirst sponsoredResolved id=\(refreshID) sponsoredCount=\(sponsoredSites.count) topSitesCount=\(topSites.count)",
                level: .debug,
                category: .homepage
            )
            dispatchTopSitesRetrievedAction(for: action.windowUUID, topSites: topSites)
            return
        }

        logger.log(
            "\(FreezeDiag.prefix)[TopSites] fullRefresh start id=\(refreshID) window=\(FreezeDiag.shortWindowID(action.windowUUID)) appState=\(FreezeDiag.applicationState)",
            level: .debug,
            category: .homepage
        )
        async let sponsoredSites = await self.topSitesManager.fetchSponsoredSites()
        async let otherSites = await self.topSitesManager.getOtherSites()
        let topSites = await self.topSitesManager.recalculateTopSites(otherSites: otherSites, sponsoredSites: sponsoredSites)
        logger.log(
            "\(FreezeDiag.prefix)[TopSites] fullRefresh resolved id=\(refreshID) topSitesCount=\(topSites.count)",
            level: .debug,
            category: .homepage
        )
        dispatchTopSitesRetrievedAction(for: action.windowUUID, topSites: topSites)
    }

    private func fetchSponsoredSitesInBackground(refreshID: Int) -> Task<[Site], Never> {
        logger.log(
            "\(FreezeDiag.prefix)[TopSites] sponsoredTask start id=\(refreshID) appState=\(FreezeDiag.applicationState)",
            level: .debug,
            category: .homepage
        )
        return Task { [topSitesManager, logger] in
            let start = Date()
            let sites = await topSitesManager.fetchSponsoredSites()
            logger.log(
                "\(FreezeDiag.prefix)[TopSites] sponsoredTask end id=\(refreshID) durationMs=\(FreezeDiag.durationMs(since: start)) sponsoredCount=\(sites.count) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                level: Task.isCancelled ? .warning : .debug,
                category: .homepage
            )
            return sites
        }
    }

    private func dispatchTopSitesRetrievedAction(for windowUUID: WindowUUID, topSites: [TopSiteConfiguration]) {
        logger.log(
            "\(FreezeDiag.prefix)[TopSites] dispatch retrievedUpdatedSites window=\(FreezeDiag.shortWindowID(windowUUID)) appState=\(FreezeDiag.applicationState) topSitesCount=\(topSites.count)",
            level: FreezeDiag.isApplicationActive ? .debug : .warning,
            category: .homepage
        )
        store.dispatch(
            TopSitesAction(
                topSites: topSites,
                shouldShowAddShortcutTile: featureFlagsProvider.isEnabled(.homepageAddShortcutTile),
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
        unifiedAdsTelemetry.sendImpressionTelemetry(tileSite: telemetryMetadata.topSiteConfiguration.site, position: telemetryMetadata.position)
    }

    private func sendSponsoredTappedTracking(with topSiteConfig: TopSiteConfiguration, and position: Int) {
        guard topSiteConfig.site.isSponsoredSite else { return }
        unifiedAdsTelemetry.sendClickTelemetry(tileSite: topSiteConfig.site, position: position)
    }

    private func sendOpenInPrivateTelemetry(for action: Action) {
        guard case .topSite = (action as? ContextMenuAction)?.menuType else {
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

    private func handleShortcutPinnedTelemetry(for action: Action) {
        guard let source = (action as? TopSitesAction)?.shortcutPinnedSource else {
            self.logger.log(
                "Unable to retrieve shortcut pinned source for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        homepageTelemetry.sendTopSitesShortcutPinnedEvent(source: source)
    }

    private func handleShortcutUnpinnedTelemetry(for action: Action) {
        guard let source = (action as? TopSitesAction)?.shortcutUnpinnedSource else {
            self.logger.log(
                "Unable to retrieve shortcut unpinned source for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        homepageTelemetry.sendTopSitesShortcutUnpinnedEvent(source: source)
    }

    private func sendBookmarkOpenTelemetry(with urlString: String) {
        let start = Date()
        let host = FreezeDiag.host(from: urlString)
        logger.log(
            "\(FreezeDiag.prefix)[BookmarkTelemetry] isBookmarked wait start isMainThread=\(Thread.isMainThread) appState=\(FreezeDiag.applicationState) host=\(host)",
            level: .debug,
            category: .storage
        )
        let isBookmarked = profile.places.isBookmarked(url: urlString).value.successValue ?? false
        let durationMs = FreezeDiag.durationMs(since: start)
        logger.log(
            "\(FreezeDiag.prefix)[BookmarkTelemetry] isBookmarked wait end durationMs=\(durationMs) isMainThread=\(Thread.isMainThread) appState=\(FreezeDiag.applicationState) host=\(host) isBookmarked=\(isBookmarked)",
            level: durationMs > 100 ? .warning : .debug,
            category: .storage
        )
        guard isBookmarked else { return }
        bookmarksTelemetry.openBookmarksSite(eventLabel: .topSites)
    }
}

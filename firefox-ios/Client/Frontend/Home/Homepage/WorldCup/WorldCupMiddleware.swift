// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux
import Shared

/// Thin Redux adapter for the WorldCup feature. The polling lifecycle,
/// `/matches` + `/live` plumbing, and view-model assembly live in
/// `WorldCupFeed`. This middleware just routes Redux actions to the feed
/// and dispatches the feed's `Snapshot` back into the store.
@MainActor
final class WorldCupMiddleware {
    private let worldCupStore: WorldCupStoreProtocol
    private let feed: WorldCupFeed?
    private let logger: Logger
    private var lastWindowUUID: WindowUUID?
    private var lastActionType = "<none>"
    /// Wether the homepage is currently displayed on screen
    private var homepageIsOnScreen = false

    convenience init() {
        let store = WorldCupStore()
        let feed = WorldCupMiddleware.makeDefaultFeed(store: store)
        self.init(worldCupStore: store, feed: feed)
    }

    init(worldCupStore: WorldCupStoreProtocol,
         feed: WorldCupFeed?,
         logger: Logger = DefaultLogger.shared) {
        self.worldCupStore = worldCupStore
        self.feed = feed
        self.logger = logger
        feed?.onUpdate = { [weak self] snapshot in
            self?.dispatch(snapshot: snapshot, reason: "feedUpdate")
        }
    }

    lazy var worldCupProvider: Middleware<AppState> = { _, action in
        self.handle(action: action)
    }

    private func handle(action: Action) {
        lastWindowUUID = action.windowUUID
        lastActionType = String(describing: action.actionType)
        switch action.actionType {
        case HomepageActionType.initialize,
             HomepageMiddlewareActionType.didBecomeActive,
             WorldCupActionType.retryMatchesFetch:
            startFeed(windowUUID: action.windowUUID)
        case HomepageActionType.viewDidAppear:
            updateHomepageVisibility(true, windowUUID: action.windowUUID)
        case HomepageActionType.viewWillDisappear:
            updateHomepageVisibility(false, windowUUID: action.windowUUID)
        case WorldCupActionType.didChangeHomepageSettings:
            dispatch(snapshot: feed?.latestSnapshot ?? .empty, reason: "didChangeHomepageSettings")
        case WorldCupActionType.removeHomepageCard:
            removeHomepageCard(windowUUID: action.windowUUID)
        case WorldCupActionType.selectTeam:
            let countryId = (action as? WorldCupAction)?.selectedCountryId
            worldCupStore.setSelectedTeam(countryId: countryId)
            startFeed(windowUUID: action.windowUUID)
        case WorldCupActionType.worldCupDidStart:
            dispatch(snapshot: feed?.latestSnapshot ?? .empty, reason: "worldCupDidStart")
        default:
            break
        }
    }

    private func updateHomepageVisibility(_ isVisible: Bool, windowUUID: WindowUUID) {
        homepageIsOnScreen = isVisible
        logger.log(
            "\(FreezeDiag.prefix)[WorldCup] homepage visibility changed visible=\(isVisible) window=\(FreezeDiag.shortWindowID(windowUUID)) appState=\(FreezeDiag.applicationState)",
            level: .debug,
            category: .homepage
        )
    }

    private func removeHomepageCard(windowUUID: WindowUUID) {
        worldCupStore.setIsHomepageSectionEnabled(false)
        logger.log(
            "\(FreezeDiag.prefix)[WorldCup] feed.stop reason=removeHomepageCard window=\(FreezeDiag.shortWindowID(windowUUID)) appState=\(FreezeDiag.applicationState)",
            level: .info,
            category: .homepage
        )
        feed?.stop()
        dispatch(snapshot: .empty, reason: "removeHomepageCard")
    }

    private func startFeed(windowUUID: WindowUUID) {
        logger.log(
            "\(FreezeDiag.prefix)[WorldCup] startFeed requested action=\(lastActionType) window=\(FreezeDiag.shortWindowID(windowUUID)) appState=\(FreezeDiag.applicationState) milestone2=\(worldCupStore.isMilestone2) selectedTeam=\(worldCupStore.selectedTeam ?? "<nil>")",
            level: .info,
            category: .homepage
        )
        guard worldCupStore.isMilestone2, let feed else {
            dispatch(snapshot: .empty, reason: "startFeedUnavailable")
            return
        }
        feed.start()
    }

    private func dispatch(snapshot: WorldCupFeed.Snapshot, reason: String) {
        guard let windowUUID = lastWindowUUID else { return }
        let level: LoggerLevel = FreezeDiag.isApplicationActive ? .info : .warning
        logger.log(
            "\(FreezeDiag.prefix)[WorldCup] dispatchSnapshot reason=\(reason) action=\(lastActionType) appState=\(FreezeDiag.applicationState) homepageOnScreen=\(homepageIsOnScreen) window=\(FreezeDiag.shortWindowID(windowUUID)) matches=\(snapshot.matches.count) apiError=\(snapshot.apiError != nil) selectedTeam=\(worldCupStore.selectedTeam ?? "<nil>")",
            level: level,
            category: .homepage
        )
        store.dispatch(
            WorldCupAction(
                windowUUID: windowUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: worldCupStore.isFeatureEnabledAndSectionEnabled,
                shouldShowMilestone2: worldCupStore.isMilestone2,
                hasWorldCupStarted: worldCupStore.hasWorldCupStarted,
                selectedCountryId: worldCupStore.selectedTeam,
                matches: snapshot.matches,
                apiError: snapshot.apiError,
                defaultMatchIndex: snapshot.defaultMatchIndex,
                shouldShowConfetti: resolveShouldShowConfetti(for: snapshot)
            )
        )
    }

    private func resolveShouldShowConfetti(for snapshot: WorldCupFeed.Snapshot) -> Bool {
        // If the homepage isn't visible, don't resolve the confetti state: it would
        // be consumed while off screen and never trigger the animation.
        guard homepageIsOnScreen, worldCupStore.isCelebrationAnimationEnabled else { return false }

        if let team = worldCupStore.selectedTeam {
            guard let defaultCard = snapshot.matches[safe: snapshot.defaultMatchIndex] else { return false }
            return celebratesNewWin(
                winningIDs: Set(snapshot.matches.flatMap { $0.winningMatchIDs(for: team) }),
                celebratableIDs: Set(defaultCard.winningMatchIDs(for: team))
            )
        }
        let cardIndex = snapshot.defaultMatchIndex - 1
        guard let card = snapshot.matches[safe: cardIndex],
              let winner = card.winnerThirdPlaceOrFinal else { return false }
        let winningIDs = Set(card.winningMatchIDs(for: winner.teamKey))
        return celebratesNewWin(winningIDs: winningIDs, celebratableIDs: winningIDs)
    }

    /// Folds `winningIDs` into the persisted seen set and reports whether any of
    /// `celebratableIDs` is a newly-seen win.
    private func celebratesNewWin(winningIDs: Set<String>, celebratableIDs: Set<String>) -> Bool {
        guard !winningIDs.isEmpty else { return false }
        let seen = worldCupStore.seenWinningMatchIDs
        let newWins = winningIDs.subtracting(seen)
        worldCupStore.setSeenWinningMatchIDs(seen.union(winningIDs))
        return !celebratableIDs.isDisjoint(with: newWins)
    }

    private static func makeDefaultFeed(store: WorldCupStoreProtocol) -> WorldCupFeed? {
        guard let apiClient = WorldCupAPIClient.makeDefault() else { return nil }
        let prefs = (AppContainer.shared.resolve() as Profile).prefs
        let usesDevServerTimeline = prefs.stringForKey(PrefsKeys.HomepageSettings.WorldCupBaseHost) != nil
        return WorldCupFeed(
            apiClient: apiClient,
            usesDevServerTimeline: usesDevServerTimeline,
            selectedTeamProvider: { store.selectedTeam }
        )
    }
}

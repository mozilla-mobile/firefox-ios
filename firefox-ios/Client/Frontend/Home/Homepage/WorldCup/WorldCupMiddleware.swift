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
    private let feed: WorldCupFeedProtocol?
    private var lastWindowUUID: WindowUUID?
    /// Wether the homepage is currently displayed on screen
    private var homepageIsOnScreen = false

    convenience init() {
        let store = WorldCupStore()
        let feed = WorldCupMiddleware.makeDefaultFeed(store: store)
        self.init(worldCupStore: store, feed: feed)
    }

    init(worldCupStore: WorldCupStoreProtocol, feed: WorldCupFeedProtocol?) {
        self.worldCupStore = worldCupStore
        self.feed = feed
        feed?.onUpdate = { [weak self] snapshot in
            self?.dispatch(snapshot: snapshot)
        }
    }

    lazy var worldCupProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    lazy var modernProvider: MiddlewareMethod<AppState> = { [self] state, action, windowUUID in
        // Does not test any modern actions
    }

    lazy var legacyProvider: LegacyMiddlewareMethod<AppState> = { [self] state, action in
        self.lastWindowUUID = action.windowUUID
        switch action.actionType {
        case HomepageActionType.initialize,
             HomepageMiddlewareActionType.didBecomeActive,
             WorldCupActionType.retryMatchesFetch:
            self.startFeed(windowUUID: action.windowUUID)
        case HomepageMiddlewareActionType.didEnterBackground:
            // Stop polling when the app is backgrounded so the feed calling
            // the network (and contending for shared resources) off-screen.
            // It is restarted on the next `didBecomeActive`.
            self.feed?.stop()
        case HomepageActionType.viewDidAppear:
            self.homepageIsOnScreen = true
        case HomepageActionType.viewWillDisappear:
            self.homepageIsOnScreen = false
        case WorldCupActionType.didChangeHomepageSettings:
            self.dispatch(snapshot: self.feed?.latestSnapshot ?? .empty)
            if self.worldCupStore.isFeatureEnabledAndSectionEnabled {
                self.startFeed(windowUUID: action.windowUUID)
            } else {
                self.feed?.stop()
            }
        case WorldCupActionType.removeHomepageCard:
            self.worldCupStore.setIsHomepageSectionEnabled(false)
            self.feed?.stop()
            self.dispatch(snapshot: .empty)
        case WorldCupActionType.selectTeam:
            let countryId = (action as? WorldCupAction)?.selectedCountryId
            self.worldCupStore.setSelectedTeam(countryId: countryId)
            self.startFeed(windowUUID: action.windowUUID)
        case WorldCupActionType.worldCupDidStart:
            self.dispatch(snapshot: self.feed?.latestSnapshot ?? .empty)
        default:
            break
        }
    }

    private func startFeed(windowUUID: WindowUUID) {
        guard worldCupStore.isMilestone2, let feed else {
            dispatch(snapshot: .empty)
            return
        }
        guard worldCupStore.isFeatureEnabledAndSectionEnabled else { return }
        feed.start()
    }

    private func dispatch(snapshot: WorldCupFeed.Snapshot) {
        guard let windowUUID = lastWindowUUID else { return }
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

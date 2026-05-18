// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux
import Shared

/// The middleware responsible for all the actions related to the `WorldCup` feature.
/// To keep it simple it dispatches only `WorldCupMiddlewareActionType.didUpdate`
/// that is only reduced by `WorldCupSectionState`.
@MainActor
final class WorldCupMiddleware {
    private let worldCupStore: WorldCupStoreProtocol
    private let apiClient: WorldCupAPIClientProtocol?
    private var matchesFetchTask: Task<Void, Never>?
    private var matches: [WorldCupMatches] = []
    private var defaultMatchIndex = 0

    init(
        worldCupStore: WorldCupStoreProtocol = WorldCupStore(),
        apiClient: WorldCupAPIClientProtocol? = try? WorldCupAPIClient(
            baseHost: (AppContainer.shared.resolve() as Profile)
                .prefs.stringForKey(PrefsKeys.HomepageSettings.WorldCupBaseHost)
        )
    ) {
        self.worldCupStore = worldCupStore
        self.apiClient = apiClient
    }

    lazy var worldCupProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize:
            self.scheduleMatchesFetch(windowUUID: action.windowUUID)
        case WorldCupActionType.didChangeHomepageSettings:
            self.dispatchUpdate(windowUUID: action.windowUUID)
        case WorldCupActionType.removeHomepageCard:
            self.worldCupStore.setIsHomepageSectionEnabled(false)
            self.dispatchUpdate(windowUUID: action.windowUUID)
        case WorldCupActionType.selectTeam:
            let countryId = (action as? WorldCupAction)?.selectedCountryId
            self.worldCupStore.setSelectedTeam(countryId: countryId)
            self.scheduleMatchesFetch(windowUUID: action.windowUUID)
        case WorldCupActionType.retryMatchesFetch:
            self.scheduleMatchesFetch(windowUUID: action.windowUUID)
        default:
            break
        }
    }

    private func dispatchUpdate(
        windowUUID: WindowUUID,
        apiError: WorldCupLoadError? = nil
    ) {
        store.dispatch(
            WorldCupAction(
                windowUUID: windowUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: worldCupStore.isFeatureEnabledAndSectionEnabled,
                shouldShowMilestone2: worldCupStore.isMilestone2,
                selectedCountryId: worldCupStore.selectedTeam,
                matches: matches,
                apiError: apiError,
                defaultMatchIndex: defaultMatchIndex
            )
        )
    }

    private func scheduleMatchesFetch(windowUUID: WindowUUID) {
        guard worldCupStore.isMilestone2, let apiClient else {
            dispatchUpdate(windowUUID: windowUUID)
            return
        }
        let selectedTeam = worldCupStore.selectedTeam
        matchesFetchTask?.cancel()
        matchesFetchTask = Task { [apiClient, weak self] in
            async let matchesResult = apiClient.loadMatches(team: selectedTeam)
            async let liveResult = apiClient.loadLive(team: selectedTeam)
            let (matches, live) = await (matchesResult, liveResult)
            guard !Task.isCancelled else { return }
            switch matches {
            case .success(let response):
                guard let response else { return }
                let liveIDs = Self.liveIDs(from: live)
                if selectedTeam != nil {
                    self?.matches = [WorldCupMatches(response: response, liveIDs: liveIDs)]
                    self?.defaultMatchIndex = 0
                } else {
                    let flattened = WorldCupMatches.flattened(response: response, liveIDs: liveIDs)
                    self?.matches = flattened.cards
                    self?.defaultMatchIndex = flattened.defaultIndex
                }
                self?.dispatchUpdate(windowUUID: windowUUID)
            case .failure(let error):
                self?.dispatchUpdate(windowUUID: windowUUID, apiError: error)
            }
        }
    }

    /// Pulls the `globalEventId`s out of the `/live` endpoint response. A
    /// failure on the live endpoint isn't fatal: the matches request already
    /// gives us a usable view, we just lose the live badge for this refresh.
    private static func liveIDs(
        from result: Result<WorldCupLiveResponse?, WorldCupLoadError>
    ) -> Set<Int> {
        guard case let .success(response) = result,
              let matches = response?.matches else { return [] }
        return Set(matches.map(\.globalEventId))
    }
}

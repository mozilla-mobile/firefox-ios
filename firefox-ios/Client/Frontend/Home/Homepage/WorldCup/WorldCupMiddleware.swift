// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux

/// The middleware responsible for all the actions related to the `WorldCup` feature.
/// To keep it simple it dispatches only `WorldCupMiddlewareActionType.didUpdate`
/// that is only reduced by `WorldCupSectionState`.
@MainActor
final class WorldCupMiddleware {
    private let worldCupStore: WorldCupStoreProtocol
    private let apiClient: WorldCupAPIClientProtocol?
    private var matchesFetchTask: Task<Void, Never>?
    private var matches: [WorldCupMatches] = []

    init(
        worldCupStore: WorldCupStoreProtocol = WorldCupStore(),
        apiClient: WorldCupAPIClientProtocol? = try? WorldCupAPIClient()
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
        default:
            break
        }
    }

    private func dispatchUpdate(windowUUID: WindowUUID) {
        store.dispatch(
            WorldCupAction(
                windowUUID: windowUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: worldCupStore.isFeatureEnabledAndSectionEnabled,
                shouldShowMilestone2: worldCupStore.isMilestone2,
                selectedCountryId: worldCupStore.selectedTeam,
                matches: matches
            )
        )
    }

    private func scheduleMatchesFetch(windowUUID: WindowUUID) {
        guard worldCupStore.isMilestone2, let apiClient else {
            dispatchUpdate(windowUUID: windowUUID)
            return
        }
        matchesFetchTask?.cancel()
        matchesFetchTask = Task { [apiClient, weak self] in
            let result = await apiClient.loadMatches(query: .matches, team: nil)
            guard case .success(let response) = result,
                  let response,
                  !Task.isCancelled else { return }
            let matches = WorldCupMatches(response: response)
            self?.matches = [matches]
            self?.dispatchUpdate(windowUUID: windowUUID)
        }
    }
}

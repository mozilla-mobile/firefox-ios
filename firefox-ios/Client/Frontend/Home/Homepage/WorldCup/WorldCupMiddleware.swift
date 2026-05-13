// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux

/// The middleware responsible for all the actions related to the `WorldCup` feature.
/// To keep it simple it dispatches only `WorldCupMiddlewareActionType.didUpdate` that is only reduced by `WorldCupSectionState`.
@MainActor
final class WorldCupMiddleware {
    private let worldCupStore: WorldCupStoreProtocol

    init(worldCupStore: WorldCupStoreProtocol = WorldCupStore()) {
        self.worldCupStore = worldCupStore
    }

    lazy var worldCupProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize,
             WorldCupActionType.didChangeHomepageSettings:
            self.dispatchUpdate(windowUUID: action.windowUUID)
        case WorldCupActionType.removeHomepageCard:
            self.worldCupStore.setIsHomepageSectionEnabled(false)
            self.dispatchUpdate(windowUUID: action.windowUUID)
        case WorldCupActionType.selectTeam:
            guard let countryId = (action as? WorldCupAction)?.selectedCountryId else { return }
            self.worldCupStore.setSelectedTeam(countryId: countryId)
            self.dispatchUpdate(windowUUID: action.windowUUID)
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
                selectedCountryId: worldCupStore.selectedTeam
            )
        )
    }
}

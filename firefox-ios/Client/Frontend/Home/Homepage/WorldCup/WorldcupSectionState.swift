// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux
import UIKit

/// State for the World Cup promo card displayed on the homepage.
@CopyWithUpdates
struct WorldcupSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var cardConfiguration: WorldcupCardConfiguration?

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            cardConfiguration: WorldcupSectionState.makeConfiguration()
        )
    }

    private init(windowUUID: WindowUUID, cardConfiguration: WorldcupCardConfiguration?) {
        self.windowUUID = windowUUID
        self.cardConfiguration = cardConfiguration
    }

    static let reducer: Reducer<Self> = { state, _ in
        return state.copyWithUpdates()
    }

    static func defaultState(from state: WorldcupSectionState) -> WorldcupSectionState {
        return state.copyWithUpdates()
    }

    private static func makeConfiguration() -> WorldcupCardConfiguration {
        // FIFA World Cup 2026 opens June 11, 2026
        let components = DateComponents(year: 2026, month: 6, day: 11)
        let target = Calendar.current.date(from: components) ?? Date()
        return WorldcupCardConfiguration(
            title: "Countdown to the World Cup",
            targetDate: target,
            ctaButtonLabel: "Follow Your Team",
            heroImage: UIImage(named: "worldcupHeroFox")
        )
    }
}

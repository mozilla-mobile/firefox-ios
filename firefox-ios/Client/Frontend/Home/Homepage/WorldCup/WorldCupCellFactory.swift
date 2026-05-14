// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

@MainActor
struct WorldCupCellFactory {
    /// Builds the subpages array from the given state
    static func makePages(from state: WorldCupSectionState) -> [UIView] {
        let timerView = WorldCupTimerView(windowUUID: state.windowUUID)
        timerView.configure(state: state)

        guard state.isMilestone2 else {
            return [timerView]
        }
    
        if state.apiError != nil {
            let errorView = WorldCupErrorView(windowUUID: state.windowUUID)
            errorView.configure(state: state)
            return [errorView]
        }

        let matchesViews = state.matches.map {
            let view = WorldCupMatchCardView(windowUUID: state.windowUUID)
            view.configure(with: $0)
            return view
        }
        return [timerView] + matchesViews
    }
}

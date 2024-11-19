// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// State to populate actions for the `PhotonActionSheet` view
/// Ideally, we want that view to subscribe to the store and update its state following the redux pattern
/// For now, we will instantiate this state and populate the associated view model instead to avoid
/// increasing scope of homepage rebuild project.
struct ContextMenuState {
    var actions: [[PhotonRowActions]] = [[]]

    init() {
        actions = [[getTemporaryAction()]]
    }
    // TODO: FXIOS-10613 - Update with proper actions
    private func getTemporaryAction() -> PhotonRowActions {
        return SingleActionViewModel(
            title: .OpenInNewTabContextMenuTitle,
            iconString: StandardImageIdentifiers.Large.plus,
            tapHandler: { _ in
            }).items
    }
}

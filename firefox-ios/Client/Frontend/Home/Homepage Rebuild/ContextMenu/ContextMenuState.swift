// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

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

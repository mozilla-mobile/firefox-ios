// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class MainMenuViewModel {
    let windowUUID: WindowUUID
    var isSwiping = false
    var isViewIntersected = false

    private let prefs: Prefs

    init(profile: Profile = AppContainer.shared.resolve(),
         windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.prefs = profile.prefs
    }

    func getCurrentDetent(
        for presentedController: UIPresentationController?
    ) -> UISheetPresentationController.Detent.Identifier? {
        guard let sheetController = presentedController as? UISheetPresentationController else { return nil }
        return sheetController.selectedDetentIdentifier
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

enum NavigationItemLocation {
    case Left
    case Right
}

enum NavigationItemText {
    case Done
    case Close

    func localizedString() -> String {
        switch self {
        case .Done:
            return Strings.SettingsSearchDoneButton
        case .Close:
            return Strings.CloseButtonTitle
        }
    }
}

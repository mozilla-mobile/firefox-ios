// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Child settings pages general actions
protocol GeneralSettingsDelegate: AnyObject {
    func pressedHome()
    func pressedMailApp()
    func pressedNewTab()
    func pressedSearchEngine()
    func pressedSiri()
    func pressedToolbar()
    func pressedTabs()
    func pressedTheme()
}

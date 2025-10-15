// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Child settings pages general actions
protocol GeneralSettingsDelegate: AnyObject {
    @MainActor
    func pressedCustomizeAppIcon()

    @MainActor
    func pressedHome()

    @MainActor
    func pressedNewTab()

    @MainActor
    func pressedSearchEngine()

    @MainActor
    func pressedSiri()

    @MainActor
    func pressedToolbar()

    @MainActor
    func pressedTheme()

    @MainActor
    func pressedBrowsing()

    @MainActor
    func pressedSummarize()

    @MainActor
    func pressedTranslation()

    @MainActor
    func pressedAutoFillsPasswords()
}

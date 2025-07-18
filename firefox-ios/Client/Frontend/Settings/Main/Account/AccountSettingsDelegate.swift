// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Child settings pages account actions
protocol AccountSettingsDelegate: AnyObject {
    @MainActor
    func pressedConnectSetting()

    @MainActor
    func pressedAdvancedAccountSetting()

    @MainActor
    func pressedToShowSyncContent()

    @MainActor
    func pressedToShowFirefoxAccount()

    @MainActor
    func askedToOpen(url: URL?, withTitle title: NSAttributedString?)
}

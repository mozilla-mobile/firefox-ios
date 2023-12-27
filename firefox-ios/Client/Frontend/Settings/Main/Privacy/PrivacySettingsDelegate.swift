// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Child settings pages privacy actions
protocol PrivacySettingsDelegate: AnyObject {
    func pressedCreditCard()
    func pressedClearPrivateData()
    func pressedContentBlocker()
    func pressedPasswords()
    func pressedNotifications()
    func askedToOpen(url: URL?, withTitle title: NSAttributedString?)
}

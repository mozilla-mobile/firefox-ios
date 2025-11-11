// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Child settings pages privacy actions
protocol PrivacySettingsDelegate: AnyObject {
    @MainActor
    func pressedAddressAutofill()

    @MainActor
    func pressedCreditCard()

    @MainActor
    func pressedClearPrivateData()

    @MainActor
    func pressedContentBlocker()

    @MainActor
    func pressedPasswords()

    @MainActor
    func pressedRelayMask()

    @MainActor
    func pressedNotifications()

    @MainActor
    func askedToOpen(url: URL?, withTitle title: NSAttributedString?)
}

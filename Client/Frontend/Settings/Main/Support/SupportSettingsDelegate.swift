// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Child settings pages support actions
protocol SupportSettingsDelegate: AnyObject {
    func pressedOpenSupportPage(url: URL)
    func askedToOpen(url: URL?, withTitle title: NSAttributedString?)
}

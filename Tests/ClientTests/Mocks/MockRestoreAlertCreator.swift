// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

final class MockRestoreAlertCreator: RestoreAlertCreator {
    var savedOkayCallback: (() -> Void)?
    var savedNoCallback: (() -> Void)?

    func restoreTabsAlert(okayCallback: @escaping () -> Void,
                          noCallback: @escaping () -> Void) -> UIAlertController {
        savedOkayCallback = okayCallback
        savedNoCallback = noCallback
        return UIAlertController()
    }
}

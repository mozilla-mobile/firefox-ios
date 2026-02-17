// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import SummarizeKit

class DeleteAppAttestKeySetting: HiddenSetting {
    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Delete app attest key ⚠️",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        try? KeychainAppAttestKeyIDStore().clearKeyID()
    }
}

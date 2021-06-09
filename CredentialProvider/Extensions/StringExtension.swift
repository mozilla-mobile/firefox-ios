/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    func titleFromHostname() -> String {
        guard let displayName = self.asURL?.host  else { return self }
        return displayName
            .replacingOccurrences(of: "^http://", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^https://", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^www\\d*\\.", with: "", options: .regularExpression)
    }
}

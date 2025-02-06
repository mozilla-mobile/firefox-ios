// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UIImage {
    convenience init?(themed name: String) {
        let suffix = LegacyThemeManager.instance.current.isDark ? "Dark" : ""
        self.init(named: name + suffix)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Array where Element: NSAttributedString {
    /// If the array is made up of `NSAttributedStrings`, this allows the reduction
    /// of the array into a single `NSAttributedString`.
    func joined() -> NSAttributedString {
        return self.reduce(NSMutableAttributedString()) { result, element in
            result.append(element)
            return result
        }
    }
}

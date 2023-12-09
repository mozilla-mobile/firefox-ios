// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension String {
    /// Encode HTMLStrings
    /// Also used for Strings which are not sanitized for displaying
    /// - Returns: Encoded String
    var htmlEntityEncodedString: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;", options: .literal)
            .replacingOccurrences(of: "\"", with: "&quot;", options: .literal)
            .replacingOccurrences(of: "'", with: "&#39;", options: .literal)
            .replacingOccurrences(of: "<", with: "&lt;", options: .literal)
            .replacingOccurrences(of: ">", with: "&gt;", options: .literal)
            .replacingOccurrences(of: "`", with: "&lsquo;", options: .literal)
    }
}

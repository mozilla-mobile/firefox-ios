// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The old themes fill Nova only tokens with clear colors. Call this method everywhere we
/// add the clear colors: it triggers an `assertionFailure` in debug to catch any wrong use.
public struct NovaMissingToken {
    public static func color(_ color: UIColor) -> UIColor {
        assertionFailure("Nova only token read from a non-Nova theme")
        return color
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Flags a Nova only token used in a classic theme; `reportMisuse`
/// defaults to `assertionFailure` and is overridden in tests.
public struct NovaMissingToken {

    nonisolated(unsafe) static var reportMisuse: (String) -> Void = { assertionFailure($0) }

    public static func color(_ color: UIColor) -> UIColor {
        reportMisuse("Nova only token read from a classic theme")
        return color
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// MARK: - Device-Size Helpers

extension UIDevice {
    static var isPad: Bool { current.userInterfaceIdiom == .pad }
    static var isTiny: Bool { UIScreen.main.bounds.height <= 568 }   // ~SE1
    static var isSmall: Bool { UIScreen.main.bounds.height <= 667 || isPad }
}

// MARK: - Shared UX Constants

struct SharedUX {
    static let topStackSpacing: CGFloat      = 24
    static let smallStackSpacing: CGFloat    = 8
    static let smallScrollPadding: CGFloat   = 20
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UIApplication {

    // Detect if app is running in Slide Over or Split View mode
    public var isSplitOrSlideOver: Bool {
        guard let window = self.windows.filter({ $0.isKeyWindow }).first else { return false }
        return !(window.frame.width == window.screen.bounds.width)
    }
}

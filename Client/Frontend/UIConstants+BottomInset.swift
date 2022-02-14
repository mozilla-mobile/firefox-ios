// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

extension UIConstants {
    static var BottomToolbarHeight: CGFloat {
        get {
            return ToolbarHeight + BottomInset
        }
    }

    static var BottomInset: CGFloat {
        get {
            var bottomInset: CGFloat = 0.0
            if let window = UIWindow.attachedKeyWindow {
                bottomInset = window.safeAreaInsets.bottom
            }
            return bottomInset
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol MainMenuInterface {
    var isReduceTransparencyEnabled: Bool { get }
    func backgroundAlpha() -> CGFloat
}

final class MainMenuHelper: MainMenuInterface {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.80
    }

    var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    func backgroundAlpha() -> CGFloat {
        guard !isReduceTransparencyEnabled else { return 1.0 }

        return UX.backgroundAlphaForBlur
    }
}

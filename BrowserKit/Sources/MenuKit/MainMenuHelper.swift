// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CoreFoundation
import UIKit

public protocol MainMenuInterface {
    @MainActor
    var isReduceTransparencyEnabled: Bool { get }

    @MainActor
    func backgroundAlpha() -> CGFloat
}

public final class MainMenuHelper: MainMenuInterface {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.80
    }

    public init() {}

    @MainActor
    public var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    @MainActor
    public func backgroundAlpha() -> CGFloat {
        guard !isReduceTransparencyEnabled else { return 1.0 }

        return UX.backgroundAlphaForBlur
    }
}

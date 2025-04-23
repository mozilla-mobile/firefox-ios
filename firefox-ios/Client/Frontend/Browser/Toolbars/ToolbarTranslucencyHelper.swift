// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

struct ToolbarTranslucencyHelper {
    private enum UX {
        static let backgroundAlphaForBlur: CGFloat = 0.8
    }

    func backgroundAlpha(
        isToolbarTranslucencyEnabled: Bool = FxNimbus.shared.features.toolbarRefactorFeature.value().translucency,
        isReduceTransparencyEnabled: Bool = UIAccessibility.isReduceTransparencyEnabled
    ) -> CGFloat {
        let isTranslucent = isToolbarTranslucencyEnabled && !isReduceTransparencyEnabled
        return isTranslucent ? UX.backgroundAlphaForBlur : 1.0
    }
}

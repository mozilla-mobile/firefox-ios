// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

/// Lets tests pick a tab tray UI without going through Nimbus or the device idiom.
@MainActor
struct MockTabTrayUtils: TabTrayUtils {
    var isTabTrayUIExperimentsEnabled = true
    var isTabTrayIpadUIExperimentsEnabled = true
    var isTabTrayTranslucencyEnabled = false
    var isReduceTransparencyEnabled = false
    var segmentedControlHeight: CGFloat = 0
    var displaysExperimentUI = true
    var blurs = false
    var backgroundAlphaValue: CGFloat = 1.0

    func shouldDisplayExperimentUI() -> Bool { return displaysExperimentUI }

    func shouldBlur() -> Bool { return blurs }

    func backgroundAlpha() -> CGFloat { return backgroundAlphaValue }
}

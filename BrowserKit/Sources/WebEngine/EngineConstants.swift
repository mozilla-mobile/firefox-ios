// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct EngineConstants {
    static let aboutBlank = "about:blank"
}

/// Value change type for adjusting browser page zoom.
public enum ZoomChangeValue {
    case increase
    case decrease
    case reset
    case set(CGFloat)

    static let defaultStepIncrease = 0.1
}

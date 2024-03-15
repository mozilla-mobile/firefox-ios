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

/// Describes the accessory view that should be shown above the keyboard for a given webview.
public enum EngineInputAccessoryView {
    /// Use the default accessory view (depends on currently presented web content).
    case `default`

    /// Do not show an accessory view. This overrides any engine or webview default.
    case none

    // Use a custom view (provided). Not currently needed but may be useful in the future.
    // case custom(UIView)
}

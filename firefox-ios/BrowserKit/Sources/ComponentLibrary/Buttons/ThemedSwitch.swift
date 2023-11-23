// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The themed `UISwitch` used in the ``PaddedSwitch``
public class ThemedSwitch: UISwitch, ThemeApplicable {
    private var enabledOnColor: UIColor?
    private var disabledOnColor: UIColor?
    private var enabledOffColor: UIColor?
    private var disabledOffColor: UIColor?

    override public var isEnabled: Bool {
        didSet {
            onTintColor = isEnabled ? enabledOnColor: disabledOnColor
        }
    }

    override public var isOn: Bool {
        didSet {
            tintColor = isOn ? enabledOffColor: disabledOffColor
        }
    }

    public func applyTheme(theme: Theme) {
        enabledOnColor = theme.colors.actionPrimary
        disabledOnColor = theme.colors.actionPrimary.withAlphaComponent(0.4)
        enabledOffColor = theme.colors.formSurfaceOff
        disabledOffColor = theme.colors.formSurfaceOff.withAlphaComponent(0.4)
        thumbTintColor = theme.colors.formKnob
        onTintColor = isEnabled ? enabledOnColor : disabledOnColor
    }
}

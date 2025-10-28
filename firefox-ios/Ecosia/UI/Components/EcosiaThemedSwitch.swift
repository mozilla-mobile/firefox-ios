// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class EcosiaThemedSwitch: UISwitch, ThemeApplicable {
    private var enabledThumbColor: UIColor?
    private var disabledThumbColor: UIColor?
    private var enabledBackgroundColor: UIColor?
    private var disabledBackgroundColor: UIColor?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @objc
    func valueChanged(_ control: UISwitch) {
        thumbTintColor = isOn ? enabledThumbColor : disabledThumbColor
    }

    public func applyTheme(theme: Theme) {
        enabledThumbColor = theme.colors.ecosia.switchKnobActive
        disabledThumbColor = theme.colors.ecosia.switchKnobDisabled
        enabledBackgroundColor = theme.colors.ecosia.buttonBackgroundPrimary
        disabledBackgroundColor = theme.colors.ecosia.stateDisabled
        onTintColor = enabledBackgroundColor
        tintColor = disabledBackgroundColor
        thumbTintColor = isOn ? enabledThumbColor : disabledThumbColor
    }
}

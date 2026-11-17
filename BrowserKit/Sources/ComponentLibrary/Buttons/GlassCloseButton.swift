// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A cross close button using the system glass appearance on iOS 26 and a filled capsule on earlier versions.
public final class GlassCloseButton: UIButton, ThemeApplicable {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 26, *) {
            configuration = .prominentClearGlass()
        } else {
            configuration = .filled()
            configuration?.cornerStyle = .capsule
        }
        configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?
            .withRenderingMode(.alwaysTemplate)
        scalesLargeContentImage = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(viewModel: CloseButtonViewModel) {
        accessibilityLabel = viewModel.a11yLabel
        accessibilityIdentifier = viewModel.a11yIdentifier
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        if #available(iOS 26, *) {
            tintColor = theme.colors.iconPrimary
        } else {
            configuration?.baseBackgroundColor = theme.colors.layer2
            configuration?.baseForegroundColor = theme.colors.iconPrimary
        }
    }
}

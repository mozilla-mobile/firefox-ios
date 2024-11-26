// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

open class LinkButton: UIButton, ThemeApplicable {
    private var foregroundColorNormal: UIColor = .clear
    private var foregroundColorHighlighted: UIColor = .clear
    private var backgroundColorNormal: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    open func configure(viewModel: LinkButtonViewModel) {
        guard let config = configuration else {
            return
        }
        var updatedConfiguration = config

        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = viewModel.font
            outgoing.underlineStyle = .single
            return outgoing
        }
        updatedConfiguration.contentInsets = viewModel.contentInsets

        accessibilityIdentifier = viewModel.a11yIdentifier
        contentHorizontalAlignment = viewModel.contentHorizontalAlignment

        configuration = updatedConfiguration
        layoutIfNeeded()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        switch state {
        case [.highlighted]:
            updatedConfiguration.baseForegroundColor = foregroundColorHighlighted
        default:
            updatedConfiguration.baseForegroundColor = foregroundColorNormal
        }

        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        foregroundColorNormal = theme.colors.textAccent
        foregroundColorHighlighted = theme.colors.actionPrimaryHover
        backgroundColorNormal = .clear
        setNeedsUpdateConfiguration()
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class LinkButton: UIButton, ThemeApplicable {
    var foregroundColorForState: ((UIControl.State) -> UIColor)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        backgroundColor = .clear
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
    }

    public func configure(viewModel: LinkButtonViewModel) {
        guard let config = configuration else {
            return
        }
        var updatedConfiguration = config

        accessibilityIdentifier = viewModel.a11yIdentifier

        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                   size: viewModel.fontSize)
            return outgoing
        }
        updatedConfiguration.contentInsets = viewModel.contentInsets
        configuration = updatedConfiguration

        contentHorizontalAlignment = viewModel.contentHorizontalAlignment
        layoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard let config = configuration else {
            return
        }
        var updatedConfiguration = config
        let foregroundColor = foregroundColorForState?(state)

        updatedConfiguration.baseForegroundColor = foregroundColor
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        var updatedConfiguration = configuration

        foregroundColorForState = { state in
            switch state {
            case [.highlighted]:
                return theme.colors.actionPrimaryHover
            default:
                return theme.colors.textAccent
            }
        }

        updatedConfiguration?.baseForegroundColor = foregroundColorForState?(state)
        configuration = updatedConfiguration
    }
}

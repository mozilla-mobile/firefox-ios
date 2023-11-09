// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class LinkButton: UIButton, ThemeApplicable {
    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        backgroundColor = .clear
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
    }

    public func configure(viewModel: LinkButtonViewModel) {
        accessibilityIdentifier = viewModel.a11yIdentifier

        configuration?.title = viewModel.title
        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                   size: viewModel.fontSize)
            return outgoing
        }
        configuration?.contentInsets = viewModel.contentInsets
        contentHorizontalAlignment = viewModel.contentHorizontalAlignment
        layoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        setTitleColor(theme.colors.textAccent, for: .normal)
        setTitleColor(theme.colors.actionPrimaryHover, for: .highlighted)
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class LinkButton: ResizableButton, ThemeApplicable {
    private struct UX {
        static let buttonCornerRadius: CGFloat = 13
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        titleLabel?.adjustsFontForContentSizeCategory = true
        contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                         left: UX.buttonHorizontalInset,
                                         bottom: UX.buttonVerticalInset,
                                         right: UX.buttonHorizontalInset)
    }

    public func configure(viewModel: LinkButtonViewModel) {
        accessibilityIdentifier = viewModel.a11yIdentifier
        setTitle(viewModel.title, for: .normal)
        titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                  size: viewModel.fontSize)
        titleLabel?.textAlignment = viewModel.textAlignment
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

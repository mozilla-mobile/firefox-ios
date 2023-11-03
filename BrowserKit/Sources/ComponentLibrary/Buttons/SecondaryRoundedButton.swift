// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class SecondaryRoundedButton: ResizableButton, ThemeApplicable {
    private struct UX {
        static let buttonCornerRadius: CGFloat = 12
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonFontSize: CGFloat = 16
    }

    private var highlightedTintColor: UIColor!
    private var normalTintColor: UIColor!

    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightedTintColor : normalTintColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        layer.cornerRadius = UX.buttonCornerRadius
        titleLabel?.textAlignment = .center
        titleLabel?.adjustsFontForContentSizeCategory = true
        contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                         left: UX.buttonHorizontalInset,
                                         bottom: UX.buttonVerticalInset,
                                         right: UX.buttonHorizontalInset)
    }

    public func configure(viewModel: SecondaryRoundedButtonViewModel) {
        accessibilityIdentifier = viewModel.a11yIdentifier
        setTitle(viewModel.title, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        highlightedTintColor = theme.colors.actionSecondaryHover
        normalTintColor = theme.colors.actionSecondary

        setTitleColor(theme.colors.textSecondaryAction, for: .normal)
        backgroundColor = theme.colors.actionSecondary
    }
}

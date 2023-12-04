// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public class PrimaryRoundedButton: ResizableButton, ThemeApplicable {
    private struct UX {
        static let buttonCornerRadius: CGFloat = 12
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonFontSize: CGFloat = 16

        static let contentInsets = NSDirectionalEdgeInsets(
            top: buttonVerticalInset,
            leading: buttonHorizontalInset,
            bottom: buttonVerticalInset,
            trailing: buttonHorizontalInset
        )
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

        configuration?.setFont(DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize
        ))
        layer.cornerRadius = UX.buttonCornerRadius
        titleLabel?.textAlignment = .center
        titleLabel?.adjustsFontForContentSizeCategory = true
        configuration?.contentInsets = UX.contentInsets
    }

    public func configure(viewModel: PrimaryRoundedButtonViewModel) {
        accessibilityIdentifier = viewModel.a11yIdentifier
        configuration?.title = viewModel.title

        guard let imageTitlePadding = viewModel.imageTitlePadding else { return }
        configuration?.imagePadding = imageTitlePadding
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        highlightedTintColor = theme.colors.actionPrimaryHover
        normalTintColor = theme.colors.actionPrimary

        configuration?.baseForegroundColor = theme.colors.textInverted
        backgroundColor = normalTintColor
    }
}

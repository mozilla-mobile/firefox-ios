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

        static let contentInsets = NSDirectionalEdgeInsets(
            top: buttonVerticalInset,
            leading: buttonHorizontalInset,
            bottom: buttonVerticalInset,
            trailing: buttonHorizontalInset
        )
    }

    private var highlightedBackgroundColor: UIColor!
    private var normalBackgroundColor: UIColor!
    private var foregroundColor: UIColor!

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = UX.buttonCornerRadius
        titleLabel?.textAlignment = .center
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }
        let newBackgroundColor = state == .highlighted ? highlightedBackgroundColor : normalBackgroundColor

        updatedConfiguration.baseForegroundColor = foregroundColor
        backgroundColor = newBackgroundColor

        configuration = updatedConfiguration
    }

    public func configure(viewModel: SecondaryRoundedButtonViewModel) {
        guard var updatedConfiguration = configuration else {
            return
        }

        updatedConfiguration.setFont(DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize
        ))
        updatedConfiguration.contentInsets = UX.contentInsets
        updatedConfiguration.title = viewModel.title

        accessibilityIdentifier = viewModel.a11yIdentifier

        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        highlightedBackgroundColor = theme.colors.actionSecondaryHover
        normalBackgroundColor = theme.colors.actionSecondary
        foregroundColor = theme.colors.textInverted

        setNeedsUpdateConfiguration()
    }
}

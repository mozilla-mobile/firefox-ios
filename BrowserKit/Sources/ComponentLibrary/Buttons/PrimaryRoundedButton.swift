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

    private var backgroundColorNormal: UIColor = .clear
    private var backgroundColorHighlighted: UIColor = .clear
    private var foregroundColor: UIColor = .black

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.filled()
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        switch state {
        case [.highlighted]:
            updatedConfiguration.background.backgroundColor = backgroundColorHighlighted
        default:
            updatedConfiguration.background.backgroundColor = backgroundColorNormal
        }

        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
            var container = incoming
            container.foregroundColor = self?.foregroundColor
            container.font = DefaultDynamicFontHelper.preferredBoldFont(
                withTextStyle: .callout,
                size: UX.buttonFontSize
            )
            return container
        }

        configuration = updatedConfiguration
    }

    public func configure(viewModel: PrimaryRoundedButtonViewModel) {
        guard var updatedConfiguration = configuration else {
            return
        }

        updatedConfiguration.contentInsets = UX.contentInsets
        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleAlignment = .center

        // Using a nil backgroundColorTransformer will just make the background view
        // use configuration.background.backgroundColor without any transformation
        updatedConfiguration.background.backgroundColorTransformer = nil
        updatedConfiguration.background.cornerRadius = UX.buttonCornerRadius
        updatedConfiguration.cornerStyle = .fixed

        accessibilityIdentifier = viewModel.a11yIdentifier

        guard let imageTitlePadding = viewModel.imageTitlePadding else {
            configuration = updatedConfiguration
            return
        }
        updatedConfiguration.imagePadding = imageTitlePadding
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        backgroundColorNormal = theme.colors.actionPrimary
        backgroundColorHighlighted = theme.colors.actionPrimaryHover
        foregroundColor = theme.colors.textInverted
        setNeedsUpdateConfiguration()
    }
}

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

    private var backgroundColorForState: ((UIControl.State) -> UIColor)?

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

        var updatedBackground = updatedConfiguration.background
        let backgroundColor = backgroundColorForState?(self.state) ?? UIColor.clear
        updatedBackground.backgroundColorTransformer = UIConfigurationColorTransformer { color in
            return backgroundColor
        }
        updatedConfiguration.background = updatedBackground
        configuration = updatedConfiguration
    }

    public func configure(viewModel: PrimaryRoundedButtonViewModel) {
        guard var updatedConfiguration = configuration else {
            return
        }

        updatedConfiguration.setFont(DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize
        ))
        updatedConfiguration.contentInsets = UX.contentInsets
        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleAlignment = .center

        var updatedBackground = updatedConfiguration.background
        updatedBackground.cornerRadius = UX.buttonCornerRadius
        updatedConfiguration.background = updatedBackground
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
        guard var updatedConfiguration = configuration else {
            return
        }

        var updatedBackground = updatedConfiguration.background

        backgroundColorForState = { state in
            switch state {
            case [.highlighted]:
                return theme.colors.actionPrimaryHover
            default:
                return theme.colors.actionPrimary
            }
        }

        let backgroundColor = backgroundColorForState?(self.state) ?? UIColor.clear
        updatedBackground.backgroundColorTransformer = UIConfigurationColorTransformer { color in
            return backgroundColor
        }
        updatedConfiguration.background = updatedBackground

        let foregroundColor = theme.colors.textInverted
        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var container = incoming
            container.foregroundColor = foregroundColor
            container.font = DefaultDynamicFontHelper.preferredBoldFont(
                withTextStyle: .callout,
                size: UX.buttonFontSize
            )
            return container
        }
        configuration = updatedConfiguration
    }
}

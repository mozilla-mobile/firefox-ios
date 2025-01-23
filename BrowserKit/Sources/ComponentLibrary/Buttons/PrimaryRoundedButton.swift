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

        static let contentInsets = NSDirectionalEdgeInsets(
            top: buttonVerticalInset,
            leading: buttonHorizontalInset,
            bottom: buttonVerticalInset,
            trailing: buttonHorizontalInset
        )
    }

    private var backgroundColorNormal: UIColor = .clear
    private var backgroundColorHighlighted: UIColor = .clear
    private var backgroundColorDisabled: UIColor = .clear
    private var foregroundColor: UIColor = .black
    private var foregroundColorDisabled: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.filled()
        titleLabel?.adjustsFontForContentSizeCategory = true

        // Fix for https://openradar.appspot.com/FB12472792
        titleLabel?.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        switch state {
        case [.disabled]:
            updatedConfiguration.background.backgroundColor = backgroundColorDisabled
        case [.highlighted]:
            updatedConfiguration.background.backgroundColor = backgroundColorHighlighted
        default:
            updatedConfiguration.background.backgroundColor = backgroundColorNormal
        }

        // swiftlint:disable line_length
        updatedConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
        // swiftlint:enable line_length
            var container = incoming
            if self?.state == .disabled {
                container.foregroundColor = self?.foregroundColorDisabled
            } else {
                container.foregroundColor = self?.foregroundColor
            }
            container.font = FXFontStyles.Bold.callout.scaledFont()
            return container
        }
        updatedConfiguration.imageColorTransformer = UIConfigurationColorTransformer { [weak self] color in
            if self?.state == .disabled {
                return self?.foregroundColorDisabled ?? .white
            } else {
                return self?.foregroundColor ?? .white
            }
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
        backgroundColorDisabled = theme.colors.actionPrimaryDisabled
        foregroundColor = theme.colors.textInverted
        foregroundColorDisabled = theme.colors.textInvertedDisabled
        setNeedsUpdateConfiguration()
    }
}

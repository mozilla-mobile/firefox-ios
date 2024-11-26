// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

public struct TrackingProtectionButtonModel {
    let title: String
    let a11yIdentifier: String
}

class TrackingProtectionButton: ResizableButton, ThemeApplicable {
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

    private var viewModel: TrackingProtectionButtonModel?
    private var backgroundColorNormal: UIColor = .clear
    private var foregroundColor: UIColor = .clear
    private var borderColor: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.bordered()
        titleLabel?.adjustsFontForContentSizeCategory = true
        contentHorizontalAlignment = .leading
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        let transformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
            var container = incoming
            container.foregroundColor = self?.foregroundColor
            container.backgroundColor = self?.backgroundColorNormal
            container.font = FXFontStyles.Regular.body.scaledFont()
            return container
        }
        updatedConfiguration.titleTextAttributesTransformer = transformer
        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        updatedConfiguration.contentInsets = UX.contentInsets
        updatedConfiguration.title = viewModel?.title
        updatedConfiguration.titleAlignment = .leading
        updatedConfiguration.background.customView?.layer.borderColor = borderColor.cgColor

        configuration = updatedConfiguration
    }

    func configure(viewModel: TrackingProtectionButtonModel) {
        guard var updatedConfiguration = configuration else {
            return
        }

        self.viewModel = viewModel

        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        updatedConfiguration.contentInsets = UX.contentInsets
        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleAlignment = .leading
        updatedConfiguration.background.customView?.layer.borderColor = borderColor.cgColor

//        if there were any pre-existing transformer applied to the background color,
//        it can alter the background color based on certain states or conditions.
//        By explicitly setting it to nil, we're ensuring a static background color
//        that is defined in updatedConfiguration.background.backgroundColor
        updatedConfiguration.background.backgroundColorTransformer = nil
        updatedConfiguration.background.cornerRadius = UX.buttonCornerRadius

        updatedConfiguration.cornerStyle = .fixed

        accessibilityIdentifier = viewModel.a11yIdentifier
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColorNormal = theme.colors.layer2
        foregroundColor = theme.colors.textPrimary
        setNeedsUpdateConfiguration()
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

public struct FakespotMessageCardButtonViewModel {
    let title: String
    let a11yIdentifier: String
    let type: FakespotMessageCardViewModel.CardType

    init(title: String = "",
         a11yIdentifier: String = "",
         type: FakespotMessageCardViewModel.CardType = .confirmation) {
        self.title = title
        self.a11yIdentifier = a11yIdentifier
        self.type = type
    }
}

class FakespotMessageCardButton: ResizableButton, ThemeApplicable {
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

    private var viewModel = FakespotMessageCardButtonViewModel()
    private var backgroundColorNormal: UIColor = .clear
    private var foregroundColor: UIColor = .black

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.filled()
        titleLabel?.adjustsFontForContentSizeCategory = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        updatedConfiguration.background.backgroundColor = backgroundColorNormal

        let transformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
            var container = incoming
            container.foregroundColor = self?.foregroundColor
            container.font = DefaultDynamicFontHelper.preferredBoldFont(
                withTextStyle: .callout,
                size: UX.buttonFontSize
            )
            return container
        }
        updatedConfiguration.titleTextAttributesTransformer = transformer

        configuration = updatedConfiguration
    }

    func configure(viewModel: FakespotMessageCardButtonViewModel) {
        guard var updatedConfiguration = configuration else {
            return
        }

        self.viewModel = viewModel

        updatedConfiguration.contentInsets = UX.contentInsets
        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleAlignment = .center

        // Using a nil backgroundColorTransformer will just make the background view
        // use configuration.background.backgroundColor without any transformation
        updatedConfiguration.background.backgroundColorTransformer = nil
        updatedConfiguration.background.cornerRadius = UX.buttonCornerRadius
        updatedConfiguration.cornerStyle = .fixed

        accessibilityIdentifier = viewModel.a11yIdentifier
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColorNormal = viewModel.type.primaryButtonBackground(theme: theme)
        foregroundColor = viewModel.type.primaryButtonTextColor(theme: theme)
        setNeedsUpdateConfiguration()
    }
}

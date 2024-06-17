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

        configuration = UIButton.Configuration.filled()
        titleLabel?.adjustsFontForContentSizeCategory = true
        isUserInteractionEnabled = true
        isAccessibilityElement = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else { return }

        updatedConfiguration.background.backgroundColor = switch state {
        case [.highlighted]: highlightedBackgroundColor
        default: normalBackgroundColor
        }

        updatedConfiguration.baseForegroundColor = foregroundColor

        let transformer = UIConfigurationTextAttributesTransformer { [weak foregroundColor] incoming in
            var container = incoming

            container.foregroundColor = foregroundColor
            container.font = FXFontStyles.Bold.callout.scaledFont()
            return container
        }
        updatedConfiguration.titleTextAttributesTransformer = transformer

        configuration = updatedConfiguration
    }

    public func configure(viewModel: SecondaryRoundedButtonViewModel) {
        guard var updatedConfiguration = configuration else { return }

        updatedConfiguration.contentInsets = UX.contentInsets
        updatedConfiguration.title = viewModel.title
        updatedConfiguration.titleAlignment = .center

        // Using a nil backgroundColorTransformer will just make the background view
        // use configuration.background.backgroundColor without any transformation
        updatedConfiguration.background.backgroundColorTransformer = nil
        updatedConfiguration.background.cornerRadius = UX.buttonCornerRadius
        updatedConfiguration.cornerStyle = .fixed
        addCornerRadiusForVisualEffectView(radiusSize: UX.buttonCornerRadius)

        accessibilityIdentifier = viewModel.a11yIdentifier

        configuration = updatedConfiguration
    }

    /// To keep alignment && spacing consistent between the buttons on pages,
    /// we must make the secondary button invisible if there is no
    /// secondary button in the configuration.
    public func makeButtonInvisible() {
        guard var updatedConfiguration = configuration else { return }

        isUserInteractionEnabled = false
        isAccessibilityElement = false
        normalBackgroundColor = .clear
        highlightedBackgroundColor = .clear
        foregroundColor = .clear

        // In order to have a proper height, the button needs some text. This
        // is invisible, but something sensible is used as a placeholder.
        updatedConfiguration.title = "Skip"

        configuration = updatedConfiguration

        setNeedsUpdateConfiguration()
    }

    func addCornerRadiusForVisualEffectView(radiusSize: CGFloat) {
        // Note: changing the corner radius for the subview, in this case UIVisualEffectView
        // is required for certain cases where UIVisualEffectView doesn't update with super view radius change
        for subview in self.subviews where subview is UIVisualEffectView {
            subview.layer.cornerRadius = radiusSize
        }
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        if configuration?.title == nil || !isUserInteractionEnabled {
            makeButtonInvisible()
        } else {
            highlightedBackgroundColor = theme.colors.actionSecondaryHover
            normalBackgroundColor = theme.colors.actionSecondary
            foregroundColor = theme.colors.textPrimary

            setNeedsUpdateConfiguration()
        }
    }
}

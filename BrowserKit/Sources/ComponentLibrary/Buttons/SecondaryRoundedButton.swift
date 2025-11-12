// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

// TODO: - FXIOS-14081 add glass version configuration like Secondary SwiftUI button in Modern onboarding.
public final class SecondaryRoundedButton: ResizableButton, ThemeApplicable {
    private struct UX {
        static var isGlassVersionAvailable: Bool {
            if #available(iOS 26.0, *) {
                return true
            } else {
                return false
            }
        }
        static var buttonCornerRadius: CGFloat {
            return 12.0
        }
        static var buttonVerticalInset: CGFloat {
            return isGlassVersionAvailable ? 15.0 : 12.0
        }
        static let buttonHorizontalInset: CGFloat = 16

        static let contentInsets = NSDirectionalEdgeInsets(
            top: buttonVerticalInset,
            leading: buttonHorizontalInset,
            bottom: buttonVerticalInset,
            trailing: buttonHorizontalInset
        )
    }

    private var highlightedBackgroundColor: UIColor?
    private var normalBackgroundColor: UIColor?
    private var foregroundColor: UIColor?

    override init(frame: CGRect) {
        super.init(frame: frame)

        if #available(iOS 26.0, *) {
            configuration = .prominentGlass()
            configuration?.cornerStyle = .capsule
        } else {
            configuration = .filled()
            configuration?.background.cornerRadius = UX.buttonCornerRadius
        }
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

        let transformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
            var container = incoming

            // For glass version we don't need to apply the foregrund color as it is handled by the .glassProminent config
            if #unavailable(iOS 26) {
                container.foregroundColor = self?.foregroundColor
            }
            if #available(iOS 26, *) {
                container.font = FXFontStyles.Bold.headline.scaledFont()
            } else {
                container.font = FXFontStyles.Bold.callout.scaledFont()
            }
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

        accessibilityIdentifier = viewModel.a11yIdentifier

        configuration = updatedConfiguration
    }

    /// To keep alignment && spacing consistent between the buttons on pages,
    /// we must make the secondary button invisible if there is no
    /// secondary button in the configuration.
    public func makeButtonInvisible() {
        guard var updatedConfiguration = configuration else { return }
        // With the glass version setting the alpha 0.0 is required otherwise the button is not invisible.
        alpha = 0.0
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        normalBackgroundColor = .clear
        highlightedBackgroundColor = .clear
        foregroundColor = .clear

        // In order to have a proper height, the button needs some text. This
        // is invisible, but something sensible is used as a placeholder.
        updatedConfiguration.title = "Skip"

        configuration = updatedConfiguration

        setNeedsUpdateConfiguration()
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        if configuration?.title == nil || !isUserInteractionEnabled {
            makeButtonInvisible()
        } else {
            alpha = 1.0
            highlightedBackgroundColor = theme.colors.actionSecondaryHover
            normalBackgroundColor = theme.colors.actionSecondary
            foregroundColor = theme.colors.textPrimary

            setNeedsUpdateConfiguration()
        }
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public final class RoundedButtonWithImage: UIButton, ThemeApplicable {
    private struct UX {
        static var buttonCornerRadius: CGFloat {
            if #available(iOS 26.0, *) {
                return 32
            } else {
                return 12
            }
        }
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let imagePadding: CGFloat = 8

        static let contentInsets = NSDirectionalEdgeInsets(
            top: buttonVerticalInset,
            leading: buttonHorizontalInset,
            bottom: buttonVerticalInset,
            trailing: buttonHorizontalInset
        )
    }

    private var highlightedBackgroundColor: UIColor?
    private var normalBackgroundColor: UIColor?
    private var disabledBackgroundColor: UIColor?
    private var foregroundColor: UIColor?
    private var foregroundDisabledColor: UIColor?
    private var imageTintColor: UIColor?

    private var viewModel: RoundedButtonWithImageViewModel?

    // Animation used to rotate the Sync icon 360 degrees while syncing is in progress.
    private let continuousRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")

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

        switch state {
        case [.highlighted]:
            updatedConfiguration.background.backgroundColor = highlightedBackgroundColor
        default:
            updatedConfiguration.background.backgroundColor = normalBackgroundColor
        }

        if let image = viewModel?.image {
            updatedConfiguration.image = UIImage(named: image)?.withRenderingMode(.alwaysTemplate)
            updatedConfiguration.imagePadding = UX.imagePadding
            updatedConfiguration.background.backgroundColor = disabledBackgroundColor
            updatedConfiguration.baseForegroundColor = imageTintColor
        }

        let transformer = UIConfigurationTextAttributesTransformer { [weak self] incoming in
            var container = incoming

            container.foregroundColor = if self?.viewModel?.image != nil {
                self?.foregroundDisabledColor
            } else {
                self?.foregroundColor
            }

            container.font = FXFontStyles.Regular.headline.scaledFont()
            return container
        }
        updatedConfiguration.titleTextAttributesTransformer = transformer

        configuration = updatedConfiguration
    }

    public func configure(viewModel: RoundedButtonWithImageViewModel) {
        guard var updatedConfiguration = configuration else { return }
        self.viewModel = viewModel
        updatedConfiguration.contentInsets = UX.contentInsets

        if let title = viewModel.title {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            setTitle(title, for: .normal)
            CATransaction.commit()
        }

        if viewModel.isAnimating {
            animateImage()
        } else {
            stopImageAnimation()
        }

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

    func addCornerRadiusForVisualEffectView(radiusSize: CGFloat) {
        // Note: changing the corner radius for the subview, in this case UIVisualEffectView
        // is required for certain cases where UIVisualEffectView doesn't update with super view radius change
        for subview in self.subviews where subview is UIVisualEffectView {
            subview.layer.cornerRadius = radiusSize
        }
    }

    private func animateImage() {
        // Animation that loops continuously until stopped
        continuousRotateAnimation.fromValue = 0.0
        continuousRotateAnimation.toValue = CGFloat(Double.pi)
        continuousRotateAnimation.isRemovedOnCompletion = true
        continuousRotateAnimation.duration = 0.5
        continuousRotateAnimation.repeatCount = .infinity
        isUserInteractionEnabled = false
        imageView?.layer.add(self.continuousRotateAnimation, forKey: "rotateKey")
    }

    private func stopImageAnimation() {
        isUserInteractionEnabled = true
        imageView?.layer.removeAllAnimations()
    }

    // MARK: ThemeApplicable

    public func applyTheme(theme: Theme) {
        highlightedBackgroundColor = theme.colors.actionSecondaryHover
        normalBackgroundColor = theme.colors.actionSecondary
        foregroundColor = theme.colors.textPrimary
        disabledBackgroundColor = theme.colors.actionSecondaryDisabled
        foregroundDisabledColor = theme.colors.textDisabled
        imageTintColor = theme.colors.iconAccentBlue

        setNeedsUpdateConfiguration()
    }
}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Custom UIBarButtonItem with an autofill accessory view.
///
/// This class provides a reusable and configurable autofill accessory view for use in navigation bars.
///
/// # Attributes
/// - `accessoryImageViewSize`: Size of the accessory image view.
/// - `accessoryButtonStackViewSpacing`: Spacing between the accessory image view and text label in the stack view.
/// - `cornerRadius`: Corner radius for the accessory view.
///
/// # Properties
/// - `accessoryImageViewTintColor`: Tint color for the accessory image view.
/// - `backgroundColor`: Background color for the accessory view.
///
/// # Methods
/// - `init(image:labelText:tappedAction:)`: Initializes the accessory view with an image, label, and optional tap action.
/// - `tappedAccessoryButton()`: Handles the tap action on the accessory view.
final class AutofillAccessoryViewButtonItem: UIBarButtonItem {
    // MARK: - Constants
    private struct UX {
        static let accessoryImageViewSize: CGFloat = 24
        static let accessoryButtonStackViewSpacing: CGFloat = 2
        static let cornerRadius: CGFloat = 4
        static let contentHorizontalInset: CGFloat = 16
    }

    // MARK: - Properties
    private let containerView = UIView()
    private let accessoryImageView: UIImageView
    private let useAccessoryTextLabel: UILabel
    private let tappedAccessoryButtonAction: (@MainActor () -> Void)?

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [accessoryImageView, useAccessoryTextLabel])
        stackView.spacing = UX.accessoryButtonStackViewSpacing
        return stackView
    }()

    /// Tint color for the accessory image view.
    var accessoryImageViewTintColor: UIColor? {
        get {
            return accessoryImageView.tintColor
        }
        set {
            accessoryImageView.tintColor = newValue
        }
    }

    /// Background color for the accessory view.
    var backgroundColor: UIColor? {
        didSet {
            updateBackgroundColor()
        }
    }

    // MARK: - Initialization
    /// Initializes the accessory view with an image, label, and optional tap action.
    /// - Parameters:
    ///   - image: The image for the accessory image view.
    ///   - labelText: The text for the accessory view label.
    ///   - tappedAction: The closure to be executed when the accessory view is tapped.
    init(
        image: UIImage?,
        labelText: String,
        tappedAction: (@MainActor () -> Void)? = nil
    ) {
        self.accessoryImageView = .build { imageView in
            imageView.image = image?.withRenderingMode(.alwaysTemplate)
            imageView.contentMode = .scaleAspectFit
            imageView.accessibilityElementsHidden = true

            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: UX.accessoryImageViewSize),
                imageView.heightAnchor.constraint(equalToConstant: UX.accessoryImageViewSize)
            ])
        }

        self.useAccessoryTextLabel = .build { label in
            label.font = FXFontStyles.Bold.callout.scaledFont()
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.65
            label.text = labelText
            label.numberOfLines = 1
            label.accessibilityTraits = .button
        }

        self.tappedAccessoryButtonAction = tappedAction
        super.init()
        setup()
        configureOverflowBehavior(image: image, labelText: labelText)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setup() {
        configureAccessibility()
        let stackViewTapped = UITapGestureRecognizer(target: self, action: #selector(tappedAccessoryButton))

        // Add the stack view to the container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 26.0, *) {
            sharesBackground = false
        }

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                      constant: UX.contentHorizontalInset),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                       constant: -UX.contentHorizontalInset),
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        containerView.layer.cornerRadius = UX.cornerRadius
        containerView.addGestureRecognizer(stackViewTapped)

        // Set the custom view as the container view
        self.customView = containerView
    }

    private func configureAccessibility() {
        let isiOS26Available: Bool = if #available(iOS 26, *) {
            true
        } else {
            false
        }
        accessoryImageView.accessibilityElementsHidden = !isiOS26Available
        accessoryImageView.accessibilityTraits = isiOS26Available ? .button : .none
        useAccessoryTextLabel.accessibilityTraits = isiOS26Available ? .none : .button
    }

    private func updateBackgroundColor() {
        if let backgroundColor {
            customView?.backgroundColor = backgroundColor
        }
    }

    private func configureOverflowBehavior(image: UIImage?, labelText: String) {
        if #available(iOS 16.0, *) {
            menuRepresentation = UIAction(title: labelText, image: image) { [weak self] _ in
                self?.tappedAccessoryButton()
            }
        }
    }

    // MARK: - Actions
    @objc
    private func tappedAccessoryButton() {
        tappedAccessoryButtonAction?()
    }
}

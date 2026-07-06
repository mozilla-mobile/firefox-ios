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
        // Horizontal padding around the content used to cap the pill's fill width
        static let contentHorizontalPadding: CGFloat = 64
    }

    // MARK: - Properties
    private let containerView = UIView()
    private let accessoryImageView: UIImageView
    private let useAccessoryTextLabel: UILabel
    private let tappedAccessoryButtonAction: (@MainActor () -> Void)?

    /// Optional explicit width constraint so the pill can fill the available toolbar space on iOS 26 iPhone
    private lazy var fillWidthConstraint: NSLayoutConstraint = {
        let constraint = containerView.widthAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultHigh
        return constraint
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [accessoryImageView, useAccessoryTextLabel])
        stackView.spacing = UX.accessoryButtonStackViewSpacing
        return stackView
    }()

    /// Natural width of the icon + label, independent of the pill's fill width.
    private var contentWidth: CGFloat {
        contentStackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
    }

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
            label.numberOfLines = 0
            label.accessibilityTraits = .button
        }

        self.tappedAccessoryButtonAction = tappedAction
        super.init()
        setup()
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

        let leadingConstraint: NSLayoutConstraint
        let trailingConstraint: NSLayoutConstraint
        if #available(iOS 26.0, *) {
            sharesBackground = false
            // Content is centered and clamped inside a container whose width is set externally in `applyFillWidth`
            contentStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
            leadingConstraint = contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor)
            trailingConstraint = contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor)
        } else {
            // Pre-iOS 26: content fills the container (centered by the toolbar's flexible spaces).
            leadingConstraint = contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            trailingConstraint = contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        }

        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        containerView.layer.cornerRadius = UX.cornerRadius
        containerView.addGestureRecognizer(stackViewTapped)

        // Set the custom view as the container view
        self.customView = containerView
    }

    /// Sizes the pill to the toolbar space reported by `AccessoryViewProvider`, capped so it stays a comfortable
    /// width around its content. Passing `nil` (pre-26) sizes the pill to content via the setup constraints.
    func applyFillWidth(_ availableWidth: CGFloat?) {
        guard let availableWidth, availableWidth > 0 else {
            fillWidthConstraint.isActive = false
            return
        }

        let width = min(availableWidth, contentWidth + UX.contentHorizontalPadding * 2)
        if fillWidthConstraint.constant != width {
            fillWidthConstraint.constant = width
        }
        fillWidthConstraint.isActive = true
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

    // MARK: - Actions
    @objc
    private func tappedAccessoryButton() {
        tappedAccessoryButtonAction?()
    }
}

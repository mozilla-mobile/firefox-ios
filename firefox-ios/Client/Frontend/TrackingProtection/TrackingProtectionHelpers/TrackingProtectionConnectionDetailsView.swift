// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class TrackingProtectionConnectionDetailsView: UIView {
    private struct UX {
        static let foxImageSize: CGFloat = 100
        static let connectionDetailsLabelsVerticalSpacing: CGFloat = 12
        static let connectionDetailsLabelBottomSpacing: CGFloat = 28
        static let connectionDetailsStackSpacing = 8.0
    }

    private let connectionDetailsContentView: UIView = .build { view in
        view.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        view.layer.masksToBounds = true
    }

    private let foxStatusImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
    }

    private var connectionDetailsLabelsContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private var connectionDetailsTitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }

    private let connectionDetailsStatusLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }

    private var viewConstraints: [NSLayoutConstraint] = []

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.layer.masksToBounds = true
        connectionDetailsLabelsContainer.addSubview(connectionDetailsTitleLabel)
        connectionDetailsLabelsContainer.addSubview(connectionDetailsStatusLabel)
        connectionDetailsContentView.addSubviews(foxStatusImage, connectionDetailsLabelsContainer)
        self.addSubview(connectionDetailsContentView)
    }

    private func updateLayout(isAccessibilityCategory: Bool) {
        removeConstraints(constraints)
        connectionDetailsContentView.removeConstraints(connectionDetailsContentView.constraints)
        foxStatusImage.removeConstraints(foxStatusImage.constraints)
        viewConstraints.removeAll()
        viewConstraints.append(contentsOf: [
            // Content
            connectionDetailsContentView.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: TPMenuUX.UX.connectionDetailsHeaderMargins
            ),
            connectionDetailsContentView.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -TPMenuUX.UX.connectionDetailsHeaderMargins
            ),
            connectionDetailsContentView.topAnchor.constraint(equalTo: self.topAnchor,
                                                              constant: TPMenuUX.UX.connectionDetailsHeaderMargins),
            connectionDetailsContentView.bottomAnchor.constraint(equalTo: self.bottomAnchor,
                                                                 constant: -TPMenuUX.UX.connectionDetailsHeaderMargins / 2),

            // Labels
            connectionDetailsTitleLabel.leadingAnchor.constraint(equalTo: connectionDetailsLabelsContainer.leadingAnchor),
            connectionDetailsTitleLabel.trailingAnchor.constraint(equalTo: connectionDetailsLabelsContainer.trailingAnchor),
            connectionDetailsTitleLabel.bottomAnchor.constraint(
                equalTo: connectionDetailsLabelsContainer.centerYAnchor,
                constant: -UX.connectionDetailsLabelsVerticalSpacing / 2
            ),

            connectionDetailsStatusLabel.leadingAnchor.constraint(equalTo: connectionDetailsLabelsContainer.leadingAnchor),
            connectionDetailsStatusLabel.trailingAnchor.constraint(equalTo: connectionDetailsLabelsContainer.trailingAnchor),
            connectionDetailsStatusLabel.topAnchor.constraint(
                equalTo: connectionDetailsLabelsContainer.centerYAnchor,
                constant: UX.connectionDetailsLabelsVerticalSpacing / 2
            ),
            connectionDetailsStatusLabel.bottomAnchor.constraint(
                lessThanOrEqualTo: connectionDetailsLabelsContainer.bottomAnchor
            ),

            // Image
            foxStatusImage.leadingAnchor.constraint(
                equalTo: connectionDetailsContentView.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            foxStatusImage.topAnchor.constraint(
                equalTo: connectionDetailsContentView.topAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            foxStatusImage.heightAnchor.constraint(equalToConstant: UX.foxImageSize),
            foxStatusImage.widthAnchor.constraint(equalToConstant: UX.foxImageSize),

            // Labels
            connectionDetailsLabelsContainer.bottomAnchor.constraint(
                equalTo: connectionDetailsContentView.bottomAnchor,
                constant: -UX.connectionDetailsLabelBottomSpacing / 2
            ),
            connectionDetailsLabelsContainer.trailingAnchor.constraint(equalTo:
                                                                        connectionDetailsContentView.trailingAnchor,
                                                                       constant: -TPMenuUX.UX.horizontalMargin),
            connectionDetailsLabelsContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.foxImageSize)
        ])
        viewConstraints.append(connectionDetailsLabelsContainer.leadingAnchor.constraint(
            equalTo: isAccessibilityCategory ?
            connectionDetailsContentView.leadingAnchor : foxStatusImage.trailingAnchor,
            constant: TPMenuUX.UX.horizontalMargin))
        viewConstraints.append(connectionDetailsLabelsContainer.topAnchor.constraint(
            equalTo: isAccessibilityCategory ?
            foxStatusImage.bottomAnchor : connectionDetailsContentView.topAnchor,
            constant: TPMenuUX.UX.horizontalMargin
        ))
        NSLayoutConstraint.activate(viewConstraints)
    }

    func adjustLayout() {
        updateLayout(isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
    }

    func setupDetails(color: UIColor? = nil, title: String, status: String, image: UIImage?) {
        connectionDetailsContentView.backgroundColor = color
        connectionDetailsTitleLabel.text = title
        connectionDetailsStatusLabel.text = status
        foxStatusImage.image = image
    }

    func setupAccessibilityIdentifiers(foxImageA11yId: String) {
        foxStatusImage.accessibilityIdentifier = foxImageA11yId
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layerAccentPrivateNonOpaque
    }
}

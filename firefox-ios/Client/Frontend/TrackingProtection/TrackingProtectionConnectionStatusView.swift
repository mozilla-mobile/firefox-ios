// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class TrackingProtectionConnectionStatusView: UIView, ThemeApplicable {
    private struct UX {
        static let connectionStatusLabelConstraintConstant = 16.0
        static let toggleLabelsContainerConstraintConstant = 16.0
    }

    var connectionStatusButtonCallback: (() -> Void)?

    private let connectionStatusImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
    }

    private let connectionStatusLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private let connectionDetailArrow: UIImageView = .build { image in
        image.image = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
        image.transform = CGAffineTransform(rotationAngle: .pi)
    }

    private let connectionButton: UIButton = .build()

    private var lockImageHeightConstraint: NSLayoutConstraint?
    private var connectionArrowHeightConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        self.addSubviews(connectionStatusImage, connectionStatusLabel, connectionDetailArrow)
        self.addSubviews(connectionButton)

        lockImageHeightConstraint = connectionStatusImage.widthAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )
        connectionArrowHeightConstraint = connectionDetailArrow.heightAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )

        NSLayoutConstraint.activate([
            connectionStatusImage.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionStatusImage.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            lockImageHeightConstraint ?? NSLayoutConstraint(),
            connectionStatusImage.heightAnchor.constraint(equalTo: self.widthAnchor),

            connectionStatusLabel.leadingAnchor.constraint(
                equalTo: connectionStatusImage.trailingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionStatusLabel.topAnchor.constraint(equalTo: self.topAnchor,
                                                       constant: UX.connectionStatusLabelConstraintConstant),
            connectionStatusLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor,
                                                          constant: -UX.connectionStatusLabelConstraintConstant),
            connectionStatusLabel.trailingAnchor.constraint(
                equalTo: connectionDetailArrow.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),

            connectionDetailArrow.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            connectionDetailArrow.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            connectionArrowHeightConstraint!,
            connectionDetailArrow.widthAnchor.constraint(equalTo: connectionDetailArrow.heightAnchor),

            connectionButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            connectionButton.topAnchor.constraint(equalTo: self.topAnchor),
            connectionButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            connectionButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }

    func setupDetails(image: UIImage, text: String) {
        connectionStatusImage.image = image
        connectionStatusLabel.text = text
    }

    func setupAccessibilityIdentifiers(arrowImageA11yId: String, securityStatusLabelA11yId: String) {
        connectionDetailArrow.accessibilityIdentifier = arrowImageA11yId
        connectionStatusLabel.accessibilityIdentifier = securityStatusLabelA11yId
    }

    func adjustLayout() {
        let iconSize = TPMenuUX.UX.iconSize
        lockImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)
        connectionArrowHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)
    }

    func setupActions() {
        connectionButton.addTarget(self, action: #selector(connectionDetailsTapped), for: .touchUpInside)
    }

    @objc
    func connectionDetailsTapped() {
        connectionStatusButtonCallback?()
    }

    func applyTheme(theme: Theme) {
        self.backgroundColor = theme.colors.layer2
        connectionDetailArrow.tintColor = theme.colors.iconSecondary
    }

    func setConnectionStatus(image: UIImage, isConnectionSecure: Bool, theme: Theme) {
        connectionStatusImage.image = image
        if isConnectionSecure {
            connectionDetailArrow.isHidden = false
            connectionStatusImage.tintColor = theme.colors.iconPrimary
        } else {
            connectionDetailArrow.isHidden = true
        }
    }
}

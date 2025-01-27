// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class TrackingProtectionBlockedTrackersView: UIView, ThemeApplicable {
    private struct UX {
        static let trackersLabelConstraintConstant = 16.0
    }

    var trackersButtonCallback: (() -> Void)?

    private let shieldImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.image = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.shield)
            .withRenderingMode(.alwaysTemplate)
    }

    private let trackersLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
    }

    private let trackersDetailArrow: UIImageView = .build { image in
        image.image = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection()
        image.transform = CGAffineTransform(rotationAngle: .pi)
    }

    private let trackersHorizontalLine: UIView = .build()
    private let trackersButton: UIButton = .build()

    private var shieldImageHeightConstraint: NSLayoutConstraint?
    private var trackersArrowHeightConstraint: NSLayoutConstraint?
    private var trackersLabelTopConstraint: NSLayoutConstraint?
    private var trackersLabelBottomConstraint: NSLayoutConstraint?

    private var viewConstraints: [NSLayoutConstraint] = []

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.addSubviews(shieldImage, trackersLabel, trackersDetailArrow, trackersButton, trackersHorizontalLine)
    }

    private func updateLayout(isAccessibilityCategory: Bool) {
        removeConstraints(constraints)
        shieldImage.removeConstraints(shieldImage.constraints)
        viewConstraints.removeAll()
        shieldImageHeightConstraint = shieldImage.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.iconSize)
        trackersArrowHeightConstraint = trackersDetailArrow.heightAnchor.constraint(
            equalToConstant: TPMenuUX.UX.iconSize
        )

        trackersLabelTopConstraint = trackersLabel.topAnchor.constraint(
            equalTo: self.topAnchor,
            constant: UX.trackersLabelConstraintConstant)
        trackersLabelBottomConstraint = trackersLabel.bottomAnchor.constraint(
            equalTo: self.bottomAnchor,
            constant: -UX.trackersLabelConstraintConstant)

        viewConstraints.append(contentsOf: [
            shieldImage.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            shieldImage.heightAnchor.constraint(equalTo: shieldImage.widthAnchor),
            shieldImageHeightConstraint!,
            trackersLabel.leadingAnchor.constraint(
                equalTo: shieldImage.trailingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            trackersLabel.trailingAnchor.constraint(
                equalTo: trackersDetailArrow.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            trackersLabelTopConstraint ?? NSLayoutConstraint(),
            trackersLabelBottomConstraint ?? NSLayoutConstraint(),

            trackersDetailArrow.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            trackersDetailArrow.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            trackersArrowHeightConstraint!,
            trackersDetailArrow.widthAnchor.constraint(equalTo: trackersDetailArrow.heightAnchor),

            trackersButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            trackersButton.topAnchor.constraint(equalTo: self.topAnchor),
            trackersButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            trackersButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            trackersHorizontalLine.leadingAnchor.constraint(equalTo: trackersLabel.leadingAnchor),
            trackersHorizontalLine.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            trackersHorizontalLine.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
            self.bottomAnchor.constraint(equalTo: trackersHorizontalLine.bottomAnchor)
        ])
        if !isAccessibilityCategory {
            viewConstraints.append(shieldImage.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        } else {
            viewConstraints.append(shieldImage.topAnchor.constraint(equalTo: trackersLabel.topAnchor))
        }
        NSLayoutConstraint.activate(viewConstraints)
    }

    func setupDetails(for trackersBlocked: Int?) {
        let trackersString = getTrackerString(for: trackersBlocked)
        trackersButton.accessibilityLabel = trackersString
        trackersLabel.text = trackersString
        shieldImage.image = UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.shield)
            .withRenderingMode(.alwaysTemplate)
        if let trackersBlocked {
            trackersDetailArrow.isHidden = trackersBlocked == 0
        }
    }

    func setupAccessibilityIdentifiers(arrowImageA11yId: String,
                                       trackersBlockedButtonA11yId: String,
                                       shieldImageA11yId: String) {
        trackersDetailArrow.accessibilityIdentifier = arrowImageA11yId
        trackersButton.accessibilityIdentifier = trackersBlockedButtonA11yId
        shieldImage.accessibilityIdentifier = shieldImageA11yId
    }

    func adjustLayout() {
        updateLayout(isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
        let iconSize = TPMenuUX.UX.iconSize
        shieldImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)
        trackersArrowHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)
    }

    func setVisibility(isHidden: Bool) {
        self.isHidden = isHidden
        if isHidden {
            trackersLabelTopConstraint?.constant = 0
            trackersLabelBottomConstraint?.constant = 0
        } else {
            trackersLabelTopConstraint?.constant = UX.trackersLabelConstraintConstant
            trackersLabelBottomConstraint?.constant = -UX.trackersLabelConstraintConstant
        }
    }

    func setupActions() {
        trackersButton.addTarget(self, action: #selector(blockedTrackersTapped), for: .touchUpInside)
    }

    @objc
    func blockedTrackersTapped() {
        trackersButtonCallback?()
    }

    private func getTrackerString(for trackersBlocked: Int?) -> String {
        if let trackersBlocked, trackersBlocked > 0 {
            return String(format: .Menu.EnhancedTrackingProtection.trackersBlockedLabel,
                          String(trackersBlocked))
        } else {
            return .Menu.EnhancedTrackingProtection.noTrackersLabel
        }
    }

    func applyTheme(theme: Theme) {
        self.backgroundColor = theme.colors.layer2
        trackersDetailArrow.tintColor = theme.colors.iconSecondary
        shieldImage.tintColor = theme.colors.iconSecondary
        trackersHorizontalLine.backgroundColor = theme.colors.borderPrimary
    }
}

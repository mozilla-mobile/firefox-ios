// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// One expanded section's body: every `key: value` line in a single rounded card. Long values
/// wrap rather than truncate.
final class WebCompatPreviewSectionContentCell: UICollectionViewListCell, ThemeApplicable, ReusableCell {
    private enum UX {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 14.5
        static let cardCornerRadius: CGFloat = 26
    }

    /// A view rather than a `backgroundConfiguration`. A list cell masks its background's
    /// corners by group position, which here would only ever round the bottom two.
    private lazy var cardView: UIView = .build { view in
        view.layer.cornerRadius = UX.cardCornerRadius
        view.layer.cornerCurve = .continuous
    }

    private lazy var keyValueLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(cardView)
        cardView.addSubview(keyValueLabel)
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            keyValueLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.horizontalInset),
            keyValueLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.horizontalInset),
            keyValueLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.verticalInset),
            keyValueLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -UX.verticalInset)
        ])
    }

    func configure(rows: [WebCompatReportPreviewViewModel.PreviewRow], accessibilityIdentifier: String) {
        keyValueLabel.text = rows.map { "\($0.label): \($0.value.displayText)" }.joined(separator: "\n")
        self.accessibilityIdentifier = accessibilityIdentifier
        isAccessibilityElement = true
        accessibilityLabel = rows.map { "\($0.label), \($0.value.displayText)" }.joined(separator: ". ")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Half-height stops a one-line card rounding into a capsule. Zero means constraints
        // haven't resolved, and clamping to it would flatten the corners.
        guard cardView.bounds.height > 0 else { return }
        let radius = min(UX.cardCornerRadius, cardView.bounds.height / 2)
        guard cardView.layer.cornerRadius != radius else { return }
        cardView.layer.cornerRadius = radius
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundConfiguration = UIBackgroundConfiguration.clear()
        cardView.backgroundColor = theme.colors.layer5
        keyValueLabel.textColor = theme.colors.textSecondary
    }
}

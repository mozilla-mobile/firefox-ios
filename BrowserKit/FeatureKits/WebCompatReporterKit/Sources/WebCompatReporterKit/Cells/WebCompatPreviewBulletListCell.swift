// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The plain-language summary on Report Preview: a "●" label beside the text on every row.
final class WebCompatPreviewBulletListCell: UICollectionViewListCell,
                                            ThemeApplicable,
                                            ReusableCell,
                                            Notifiable {
    private typealias BulletRow = (dotLabel: UILabel, textLabel: UILabel)

    private var bullets: [String] = []
    private var bulletRows: [BulletRow] = []
    private var theme: Theme?

    private lazy var bulletsStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        let insets = WebCompatReporterUX.Card.edgeInsets
        contentView.addSubview(bulletsStackView)
        NSLayoutConstraint.activate([
            bulletsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.leading),
            bulletsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.trailing),
            bulletsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
            bulletsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom)
        ])
        applyScaledSpacing()
    }

    func configure(bullets: [String], accessibilityIdentifier: String) {
        self.accessibilityIdentifier = accessibilityIdentifier
        isAccessibilityElement = true
        accessibilityLabel = bullets.joined(separator: ". ")

        // reconfigureItems re-runs this on a theme change, so only rebuild when the copy moved.
        guard bullets != self.bullets else { return }
        self.bullets = bullets
        updateBullets()
    }

    private func updateBullets() {
        bulletsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        bulletRows = bullets.map { addRow(for: $0) }
        applyScaledSpacing()
        applyColors()
    }

    private func addRow(for bullet: String) -> BulletRow {
        let dotLabel: UILabel = .build { label in
            label.text = "●"
            label.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(
                for: FXFontStyles.Regular.footnote.systemFont()
                    .withSize(WebCompatReporterUX.Preview.bulletDotFontSize)
            )
            label.adjustsFontForContentSizeCategory = true
            label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            // The text wraps, so the dot must never be the thing that gives way.
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.isAccessibilityElement = false
        }
        let textLabel: UILabel = .build { label in
            label.text = bullet
            label.numberOfLines = 0
            label.font = FXFontStyles.Regular.footnote.scaledFont()
            label.adjustsFontForContentSizeCategory = true
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }

        let rowView: UIStackView = .build { stackView in
            stackView.axis = .horizontal
            stackView.alignment = .firstBaseline
        }
        rowView.addArrangedSubview(dotLabel)
        rowView.addArrangedSubview(textLabel)
        bulletsStackView.addArrangedSubview(rowView)
        return (dotLabel, textLabel)
    }

    private func applyScaledSpacing() {
        bulletsStackView.spacing = UIFontMetrics.default.scaledValue(
            for: WebCompatReporterUX.Preview.bulletRowSpacing
        )
        let dotSpacing = UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.Preview.bulletDotSpacing)
        for case let rowView as UIStackView in bulletsStackView.arrangedSubviews {
            rowView.spacing = dotSpacing
        }
    }

    private func applyColors() {
        guard let theme else { return }
        for row in bulletRows {
            row.dotLabel.textColor = theme.colors.iconSecondary
            row.textLabel.textColor = theme.colors.textPrimary
        }
    }

    // MARK: - Notifiable

    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        ensureMainThread { [weak self] in
            self?.applyScaledSpacing()
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        var background = UIBackgroundConfiguration.listGroupedCell()
        background.backgroundColor = theme.colors.layer5
        background.cornerRadius = WebCompatReporterUX.Card.largeCornerRadius
        backgroundConfiguration = background
        self.theme = theme
        applyColors()
    }
}

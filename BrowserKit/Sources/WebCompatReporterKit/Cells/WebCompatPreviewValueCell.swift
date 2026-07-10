// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// One `key: value` line inside an expanded Report Preview section, rendered
/// monospaced to match the Figma raw-payload view: the key is secondary, the
/// value primary, and long values (URLs) wrap instead of truncate.
final class WebCompatPreviewValueCell: UICollectionViewListCell {
    private lazy var valueLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(valueLabel)
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            valueLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: margins.topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        ])
    }

    func configure(label: String, value: String, theme: Theme) {
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        let font = UIFontMetrics(forTextStyle: .footnote).scaledFont(
            for: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        )
        let text = NSMutableAttributedString(
            string: "\(label): ",
            attributes: [.font: font, .foregroundColor: theme.colors.textSecondary]
        )
        text.append(NSAttributedString(
            string: value,
            attributes: [.font: font, .foregroundColor: theme.colors.textPrimary]
        ))
        valueLabel.attributedText = text
        // Read as a single "key, value" element to VoiceOver.
        isAccessibilityElement = true
        accessibilityLabel = "\(label), \(value)"
    }
}

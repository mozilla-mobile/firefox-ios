// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

class BlockedTrackersFooterView: UITableViewHeaderFooterView,
                                 ReusableCell {
    private enum UX {
        static let footerLeadingAnchorMultiplier: CGFloat = 1.7
    }

    let trackersBlockedInfoTextView: UITextView = .build { textView in
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.adjustsFontForContentSizeCategory = true
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers
        accessibilityIdentifier = A11y.footerView
        trackersBlockedInfoTextView.accessibilityIdentifier = A11y.trackersBlockedInfoTextView
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(trackersBlockedInfoTextView)

        NSLayoutConstraint.activate([
            trackersBlockedInfoTextView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: UX.footerLeadingAnchorMultiplier * TPMenuUX.UX.horizontalMargin // to align with the cell images
            ),
            trackersBlockedInfoTextView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            trackersBlockedInfoTextView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: TPMenuUX.UX.connectionDetailsFooterMargins / 2
            ),
            trackersBlockedInfoTextView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -TPMenuUX.UX.connectionDetailsFooterMargins
            )
        ])
    }

    func configure(
        with text: String,
        linkedText: String,
        url: URL?,
        theme: Theme,
        and delegate: UITextViewDelegate? = nil
    ) {
        trackersBlockedInfoTextView.delegate = delegate
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                // UITextView.attributedText overrides adjustsFontForContentSizeCategory behavior
                // Unlike UILabel, we must explicitly set scaledFont() in the attributed string
                .font: FXFontStyles.Regular.caption1.scaledFont(),
                .foregroundColor: theme.colors.textSecondary,
                .paragraphStyle: paragraphStyle
            ]
        )

        if let url {
            let learnMoreRange = (text as NSString).range(of: linkedText)
            attributed.addAttribute(.link, value: url, range: learnMoreRange)
        }

        trackersBlockedInfoTextView.attributedText = attributed
    }

    func applyTheme(theme: Theme) {
        trackersBlockedInfoTextView.linkTextAttributes = [
            .foregroundColor: theme.colors.textAccent
        ]
    }
}

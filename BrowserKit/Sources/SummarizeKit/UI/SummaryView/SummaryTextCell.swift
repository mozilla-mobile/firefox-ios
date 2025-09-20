// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

final class SummaryTextCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private let summaryView: UITextView = .build {
        $0.isScrollEnabled = false
        $0.font = FXFontStyles.Regular.headline.scaledFont()
        $0.showsVerticalScrollIndicator = false
        $0.adjustsFontForContentSizeCategory = true
        $0.isEditable = false
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.addSubview(summaryView)
        summaryView.pinToSuperview()
    }

    func configure(text: NSAttributedString?, a11yId: String) {
        summaryView.attributedText = text
        summaryView.accessibilityIdentifier = a11yId
        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.3
        summaryView.layer.add(transition, forKey: "fadeAnimation")
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        summaryView.backgroundColor = .clear
        summaryView.textColor = theme.colors.textPrimary
        backgroundColor = .clear
    }
}
